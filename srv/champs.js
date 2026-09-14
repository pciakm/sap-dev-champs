const cds = require('@sap/cds')
const path = require('node:path');
const fs = require('node:fs');
module.exports = class SAPDevChamps extends cds.ApplicationService { init() {

  this.on('show', function(req){
    const filePath = path.join(__dirname, './champions.txt');
    // const filePath = '../db/data/champions.txt';
    const fileContent = fs.readFileSync(filePath, 'utf8');
    const champs = fileContent.split('\n').map(line => line.trim());
 
    return champs;
  });

  return super.init()
}}
