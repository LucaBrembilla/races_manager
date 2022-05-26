const AWS = require('aws-sdk'); 
var convert = require('xml-js'); 
const { DOMParser } = require('xmldom');
var xpath = require('xpath');
const S3 = new AWS.S3(); 
const bucketName = 'tcmbucket'; 
const docClient = new AWS.DynamoDB.DocumentClient(); 
const tableName = 'Gare';
 
// TODO: FARE UNA FUNZIONE CHE TI PRENDA IL NOME DALLA TABELLA E POI LO VADA A CERCARE NEL BUCKET
// let n = 2; // TODO: N sarebbe l'id che c'è nella tabella... sarebbe meglio prenderlo direttamente da lì

//HANDLER EVENTO 
exports.handler = async function(event) { 
    let response; 
    let path  = JSON.parse(JSON.stringify(event.rawPath)); 
    switch(true) { 
    case event.requestContext.http.method === "GET" && path === "/listclasses": 
        response = await ListClasses(event); 
        break; 
    case event.requestContext.http.method === "GET" && path === "/downloadxml": 
        response = await DownloadXml(event); 
        break;
    case event.requestContext.http.method === "GET" && path === "/results": 
        response = await getResults(event); 
        break;
    case event.requestContext.http.method === "GET" && path === "/list_races":
        response = await ListRaces(event);
        break;
    case event.requestContext.http.method === 'POST' && path === '/uploadxml': 
        response = await UploadXML(event); 
        break; 
    case event.requestContext.http.method === "POST" && path === "/register_race": 
        response = await RegisterRace(event); 
        break;
    default: 
        response = buildResponse(404, '404 Not Found'); 
    } 
    return response; 
}; 

// FUNZIONE PER CAPIRE QUANTE GARE CI SONO
async function findNumberOfRaces(){
  const params = { 
    TableName: tableName, 
    Select: "COUNT" 
  };
 
  try { 
    const count = await docClient.scan(params).promise();
    return parseInt( count.Count , 10);
  }catch(e){
    return 0;
  }
}



//REGISTRARE UNA GARA 

async function RegisterRace(event){
    if(event.queryStringParameters.Auth !== 'nuvole'){ 
      return buildResponse(401, 'Non Autorizzato a caricare file'); 
    } 
 
    let n = await findNumberOfRaces();
    n = n+1; 
     var id =""+ n; 
     var token = Math.random().toString(36).replace(/[^a-z]+/g, '').substr(0, 5); 
     try { 
       const params = { 
            TableName : tableName, 
            Item: { 
               ID: id, 
               Nome: event.queryStringParameters.nome, 
               Data: event.queryStringParameters.data, 
               Email : event.queryStringParameters.email, 
               Password: token 
            } 
          }; 
        await docClient.put(params).promise(); 
        var string= "ID: " + id + "; PASSWORD: " + token; 
        return string; 
     } catch(e){ 
      return buildResponse(500, "Something failed"); 
  }
} 

//LIST CLASSES
async function ListClasses(event) { 
  try{
    const paramsT = { 
    TableName : tableName, 
    Key: { 
      ID: event.queryStringParameters.id 
      } 
    };
   
    const dataT = await docClient.get(paramsT).promise();
   
    const params = {  
      Bucket: bucketName,  
      Key: dataT.Item.Nome,  
    };
    // FIRST HOMEWORK:
    //const data = await S3.getObject(params).promise(); 
    //return convert.xml2json(data.Body.toString()); 
    const data = await S3.getObject(params).promise(); 
    const doc = new DOMParser().parseFromString(data.Body.toString(), 'text/xml'); 
    const category = doc.getElementsByTagName("Class"); 
    const stringaDiClassi = category.toString().replace(/xmlns="(.*?)"/g, '').replace(/xmlns:xsi="(.*?)"/g, '');
    const documentoClassi = new DOMParser().parseFromString(stringaDiClassi);
    
    const numberOfClasses = documentoClassi.getElementsByTagName("Class").length;
    //let string = ' "classes": [';
    let string = '[';
    let i=0;
    //const idClasse = xpath.select( "//Class/Id/text()" , documentoClassi);
    const className = xpath.select( "//Class/Name/text()" , documentoClassi);
    while(i < numberOfClasses){
      //string = string + '{"classId": "'+  idClasse[i] +'","className": "'+ className[i] +'"},'; 
      //string = string + '{"className": "'+ className[i] +'"},';
      string = string + '"' + className[i] + '" ,';
      i++;
    }
    
    string = string.substring(0, string.length-1);
    string = string + ']';

    return JSON.parse(string);
    
  }catch (err) {
    return buildResponse(500, "Something failed");
  }
}

// DOWNLOAD XML
async function DownloadXml(event) { 
  try { 
   const paramsT = { 
    TableName : tableName, 
    Key: { 
      ID: event.queryStringParameters.id 
      } 
    };
   
    const dataT = await docClient.get(paramsT).promise();
   
    const params = {  
      Bucket: bucketName,  
      Key: dataT.Item.Nome,  
    };   
     
    const data = await S3.getObject(params).promise();  
    return convert.xml2json(data.Body.toString(), {compact: true, spaces: 4} ); 
  } catch (err) { 
    return buildResponse(500, "Something failed");
  } 
 
}

// RESULTS
async function getResults(event) {
  try{
    
    const paramsT = { 
    TableName : tableName, 
    Key: { 
      ID: event.queryStringParameters.id 
      } 
    };
   
    const dataT = await docClient.get(paramsT).promise();
   
    const params = {  
      Bucket: bucketName,  
      Key: dataT.Item.Nome,  
    };   
    
    const className = event.queryStringParameters.class;
    const data = await S3.getObject(params).promise();
    let xml = (data.Body.toString()).replace(/xmlns="(.*?)"/g, '').replace(/xmlns:xsi="(.*?)"/g, '');
    const doc = new DOMParser().parseFromString(xml);
    var queryXpath = "//ClassResult[Class/Name/text()= '"+className+"']/PersonResult";
    var node = xpath.select(queryXpath, doc);
    
    const peopleDoc = new DOMParser().parseFromString(node.toString());
    const numberOfPeople = peopleDoc.getElementsByTagName("PersonResult").length;
    let string = '[';
    let i=0;
    const personId = xpath.select( "//Person/Id/text()" , peopleDoc);
    const peopleSurname = xpath.select( "//Person/Name/Family/text()" , peopleDoc);
    const peopleName = xpath.select( "//Person/Name/Given/text()" , peopleDoc);
    const peoplePosition = xpath.select( "//Result/Position/text()" , peopleDoc);
    const startTime = xpath.select( "//Result/StartTime/text()" , peopleDoc);
    const finishTime = xpath.select( "//Result/FinishTime/text()" , peopleDoc);
    const raceTime = xpath.select( "//Result/Time/text()" , peopleDoc);
    while(i < numberOfPeople){
      string = string + '{ "id":"' + personId[i] + '",';
      string = string + '"personName":"' + peopleName[i] + '",';
      string = string + '"personSurname":"' + peopleSurname[i] + '",';
      if(peoplePosition[i] === undefined)
        string = string + '"position": "Disqualified",';
      else
        string = string + '"position":"' + peoplePosition[i] + '",';
        
      string = string + '"raceTime":"' + raceTime[i] + '",';
      string = string + '"startTime":"' + startTime[i] + '",';
      string = string + '"finishTime":"' + finishTime[i] + '"},';
      i++;
    }
    
    string = string.substring(0, string.length-1);
    string = string + ']';

    return JSON.parse(string);
    //return node.toString();
    
    //return convert.xml2json( node.toString(), {compact: true, spaces: 4} );
  }catch(err) {
    return buildResponse(500, "Something failed");
  }
}

// LIST RACES
async function ListRaces(event) { 
  var string = ' "elements": ['; 
 
  try { 
    var id = 1;
    let n = await findNumberOfRaces();
    while(id<=n){ 
    
      var params = { 
        TableName : 'Gare', 
         Key: { 
          ID:""+ id 
         } 
      }; 
    var data = await docClient.get(params).promise();
 
    string = string + '{"Nome": "'+data.Item.Nome+'","Data": "'+data.Item.Data+'","ID": "'+data.Item.ID+'"},'; 
    id++; 
    } 
    string = string.substring(0, string.length -1);
    string = "{" +string+ "]}";
    string = string.substring(14, string.length -1);
    
    return JSON.parse(string); 
  } catch (err) { 
    return buildResponse(500, "Something failed");
  } 
}

async function getPassword(id){ 
  const params = { 
    TableName : 'Gare', 
    /* Item properties will depend on your application concerns */ 
    Key: { 
      ID: id
    }
  };
 
  try { 
    const data = await docClient.get(params).promise();
    return data.Item.Password;
  } catch (err) { 
    return false; 
  } 
} 

async function getNome(id){ 
  const params = { 
    TableName : 'Gare', 
    /* Item properties will depend on your application concerns */ 
    Key: { 
      ID: id 
    } 
  };
 
  try { 
    const data = await docClient.get(params).promise();
    return data.Item.Nome;
  } catch (err) { 
    return false;
  } 
} 
 
//CARICARE FILE 
async function UploadXML(event){ 
 
    //SCANSIONE 
    const id =  event.queryStringParameters.id; 
    let PSW;
     
    if(!(await getPassword(id))){ 
      PSW = event.queryStringParameters.password + "XD"; 
    }else{ 
      PSW = await getPassword(id); 
    }
     
    //CARICAMENTO 
    if( event.queryStringParameters.password !== PSW) { 
      return buildResponse(401, 'Password File Sbagliata'); 
    } 
     
     try { 
          const response = event.body; 
          const name = await getNome(id); 
          const params = { 
              Bucket: bucketName, 
              Key: name, 
              Body: response, 
              ContentType: 'application/xml; charset=utf-8' 
          };
           
          await S3.putObject(params).promise(); 
         return buildResponse(200, 'Upload Completed'); 
    } catch(e){ 
      console.log(e);
      console.log("Upload Error", e); 
    } 
  } 

  
//RESPONSE 
function buildResponse(statusCode, body) { 
  return { 
    statusCode: statusCode, 
    headers: { 
      'Content-Type': 'application/json' 
    }, 
    body: JSON.stringify(body) 
  };
}
