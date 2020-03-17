const puppeteer = require('puppeteer');
const fs = require('fs');

(async () => {

    const browser = await puppeteer.launch({executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless: false});

    const page = await browser.newPage();

    var items = [];

    for( var var_page_i = 1; var_page_i <= 309; var_page_i++ ) {

        await page.goto('https://access.redhat.com/ecosystem/search/#/category/Server?page='+var_page_i+'&sort=sortTitle%20asc&ecosystem=Red%20Hat%20Enterprise%20Linux');


        const result = await page.evaluate(() => {
            let data = []; // 初始化空数组来存储数据
            let elements = document.querySelectorAll('div.list-results > div'); // 获取所有书籍元素
    
            for (var i = 0; i < elements.length; i ++) {
                if ( elements[i].className == "list-result ng-scope" ) {
                    let vendor = elements[i].querySelector('div.vendor > a > div:nth-child(2)');

                    let var_image = elements[i].querySelector('div.vendor > a > div.logo-container.ng-binding > img');

                    let vendor_image = "";
                    if ( var_image != null ) {
                        vendor_image = var_image.src ;
                    }

                    let hardware = elements[i].querySelector('div.details > h3 > a');
    
                    let product = elements[i].querySelector('div.details > div.list-result-meta');
    
                    data.push({
                        "vendor": vendor.innerText, 
                        "hardware": hardware.innerText, 
                        "product": product.innerText,
                        "vendor_image": vendor_image,
                        "hardware_url": hardware.href
                    });

                }
            }
    
            return data; // 返回数据
        });
        await page.waitFor(1000);
        items=items.concat(result);
        console.log(result);
    }

    // console.log(items);

    const jsonString = JSON.stringify(items)
    fs.writeFile('./result.json', jsonString, err => {
        if (err) {
            console.log('Error writing file', err)
        } else {
            console.log('Successfully wrote file')
        }
    })

    await browser.close();

})();