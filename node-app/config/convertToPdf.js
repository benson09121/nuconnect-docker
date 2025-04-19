const { exec } = require('child_process');
const path = require('path');

function convertDocxToPdf(inputPath, outputPath) {
    return new Promise((resolve, reject) => {
        const command = `libreoffice --headless --convert-to pdf --outdir "${path.dirname(outputPath)}" "${inputPath}"`;

        exec(command, (error, stdout, stderr) => {
            if (error) {
                return reject(new Error(`LibreOffice conversion failed: ${stderr}`));
            }

            resolve(outputPath); // Directly resolve the provided outputPath
        });
    });
}

module.exports = convertDocxToPdf;