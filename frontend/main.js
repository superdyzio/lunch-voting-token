let options = [];
let currentAccount = null;
let contract = null;
let provider = null;

async function init() {
    const accounts = await ethereum.request({method: 'eth_accounts'});
    currentAccount = accounts[0];
    console.log(`Logged in as ${currentAccount}`);

    getContractData();
}

function getContractData() {
    fetch('http://localhost:3000/get-contract-data')
        .then(response => response.json())
        .then(async ({contractABI, contractAddress}) => {
            provider = new ethers.providers.Web3Provider(window.ethereum, 'any');
            await provider.send('eth_requestAccounts', []);
            const signer = provider.getSigner();
            contract = new ethers.Contract(contractAddress, contractABI, signer);
        });
}

async function connect() {
    const connectMetamaskButton = document.getElementById('connectMetamaskButton');
    connectMetamaskButton.setAttribute('disabled', '');
    connectMetamaskButton.innerText = 'Connected';

    const accounts = await ethereum.request({method: 'eth_requestAccounts'});
    currentAccount = accounts[0];
    console.log(`Logged in as ${currentAccount}`);
}

async function refreshData() {
    getParticipants();
    getMyBalance();

    const isParticipant = await contract.isParticipant(currentAccount);
    if (isParticipant) {
        getOptions();
    }
}

async function getParticipants() {
    const participantNames = await contract.getAllParticipantNames();
    document.getElementById('participantList').innerText = participantNames.length > 0 ? participantNames.join(', ') : 'No participants.';
}

async function getOptions() {
    const optionNames = await contract.getOptions();
    document.getElementById('optionList').innerHTML = optionNames.length > 0 ? optionNames.map(option => {
        options = [...optionNames];
        return `<li>
                    <span>${option}</span>
                    <form onsubmit='vote()'>
                        <input type='number' placeholder='Vote weight'/>
                        <button>Vote</button>
                    </form>
                </li>`
    }).join('') : `<li>No options available.</li>`;
}

async function getMyBalance() {
    const lvtBalance = await contract.balanceOf(currentAccount);
    const weiBalance = await provider.getBalance(currentAccount);
    const ethBalance = ethers.utils.formatEther(weiBalance);
    document.getElementById('myBalance').innerText = `My balance: ${lvtBalance} LVT \n ${ethBalance} ETH`;
}

async function getLastWinner() {
    const lastWinner = await contract.getLastWinner();
    document.getElementById('lastWinner').innerText = `Last winner: ${lastWinner.length > 0 ? lastWinner : 'unknown'}`;
}

async function startVoting() {
    await contract.startVoting(1000);
    console.log('Voting started');
    document.getElementById('startVoting').setAttribute('disabled', '');
    document.getElementById('endVoting').removeAttribute('disabled');
    await refreshData();
}

async function endVoting() {
    await contract.endVoting();
    console.log('Vote ended');
    document.getElementById('startVoting').removeAttribute('disabled');
    document.getElementById('endVoting').setAttribute('disabled', '');
    await getLastWinner();
}

async function addParticipant() {
    event.preventDefault();
    const address = document.getElementById('newParticipantAddress').value;
    const name = document.getElementById('newParticipantName').value;
    if (address.length === 0 || name.length === 0) {
        alert('Incomplete data!');
        return;
    }

    await contract.registerParticipant(address, name);
    console.log(`Wallet ${address} registered as ${name}`);
    document.getElementById('newParticipantForm').reset();
    await getParticipants();
}

async function addOption() {
    event.preventDefault();
    const name = document.getElementById('newOptionName').value;
    if (name.length === 0) {
        alert('Incomplete data!');
        return;
    }

    await contract.addOption(name);
    console.log(`Option ${name} added`);
    document.getElementById('newOptionForm').reset();
    await getOptions();
}

async function vote() {
    event.preventDefault();
    const input = event.target[0];
    const votes = input.value;
    const name = event.path[1].getElementsByTagName('span')[0].textContent;
    const position = options.findIndex(option => option === name);

    await contract.vote(position, votes);
    console.log(`${votes} added to ${position}`);
    input.value = null;
    await refreshData();
    await getOptions();
}
