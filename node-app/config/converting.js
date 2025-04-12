var mammoth = require("mammoth");
const puppeteer = require("puppeteer");
const { format } = require("path");

async function convertToPdf(inputDocFilePathWithFileName, outputDocFilePathWithFileName, callback) {
  mammoth.convertToHtml({
      path: inputDocFilePathWithFileName
    })
    .then(async function (result) {
      var html = result.value; // The generated HTML 
      const browser = await puppeteer.launch({
        headless: 'new',
        executablePath: '/usr/bin/google-chrome',
        args: ['--no-sandbox', '--disable-setuid-sandbox'],
      })
      const page = await browser.newPage();
      await page.setContent(html, { waitUntil: 'networkidle0' });

      await page.pdf({
        path: outputDocFilePathWithFileName,
        format : 'A4',
        printBackground: true,
        margin:{
            top: '20mm',
            bottom: '20mm',
            left: '20mm',
            right: '20mm'
        }
      });
      await browser.close();
      callback(null, { message: "PDF generated successfully" });
    })
    .done();
}

module.exports = convertToPdf;