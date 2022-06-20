function getDeployerAddress() {
    fetch('http://localhost:3000/get-deployer-address')
        .then(response => response.text())
        .then(data => console.log(data));
}
