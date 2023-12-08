const counter = document.querySelector(".counter-number");
async function updateCounter() {
    let response = await fetch("https://3eny2jdjue2uxunpan3zuonmle0unvya.lambda-url.us-east-2.on.aws/");
    let data = await response.json();
    counter.innerHTML = ` Views: ${data}`;
}

updateCounter();