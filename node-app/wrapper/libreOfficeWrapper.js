const { exec } = require('child_process');
const path = require('path');

function convertDocxToPdf(inputPath, outputDir) {
    return new Promise((resolve, reject) => {
        const command = `libreoffice --headless --convert-to pdf --outdir "${outputDir}" "${inputPath}"`;

        exec(command, (error, stdout, stderr) => {
            if (error) {
                return reject(new Error(`LibreOffice conversion failed: ${stderr}`));
            }

            const outputPdfPath = path.join(outputDir, path.basename(inputPath, '.docx') + '.pdf');
            resolve(outputPdfPath);
            console.log('stdout:', stdout);
            console.error('stderr:', stderr);
        });
    });
}
module.exports = convertDocxToPdf;