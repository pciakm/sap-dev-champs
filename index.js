const path = require('node:path');
const fs = require('node:fs');
const output = require('./output.js')

const app = () => {
    const filePath = path.join(__dirname, './champions.txt');
    const fileContent = fs.readFileSync(filePath, 'utf8');
    champs = fileContent.split('\n').map(line => line.trim());
    
    champs.forEach((champ)=>output.printName(champ));        
};
app();
