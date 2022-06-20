let options = [];

function refreshData() {
    getParticipants();
    getOptions();
    getMyBalance();
}

function getParticipants() {
    fetch('http://localhost:3000/get-all-participant-names')
        .then(response => response.json())
        .then(participantNames => {
            document.getElementById('participantList').innerText = participantNames.length > 0 ? participantNames.join(', ') : 'No participants.';
        });
}

function getOptions() {
    fetch('http://localhost:3000/get-options')
        .then(response => response.json())
        .then(optionNames => {
            document.getElementById('optionList').innerHTML = optionNames.length > 0 ? optionNames.map(option => {
                options = [...optionNames];
                return `<li>
                            <span>${option}</span>
                            <form onsubmit="vote()">
                                <input type="number" placeholder="Vote weight"/>
                                <button>Vote</button>
                            </form>
                        </li>`
            }).join('') : `<li>No options available.</li>`;
        });
}

function getMyBalance() {
    fetch('http://localhost:3000/get-my-balance')
        .then(response => response.json())
        .then(balance => {
            document.getElementById('myBalance').innerText = `My balance: ${balance.balance} LVT \n ${balance.ethBalance} ETH`;
        });
}

function getLastWinner() {
    fetch('http://localhost:3000/get-last-winner')
        .then(response => response.text())
        .then(lastWinner => {
            document.getElementById('lastWinner').innerText = `Last winner: ${lastWinner.length > 0 ? lastWinner : 'unknown'}`;
        });
}

function startVoting() {
    document.getElementById('startVoting').setAttribute('disabled', '');
    document.getElementById('endVoting').removeAttribute('disabled');

    fetch('http://localhost:3000/start-voting', {
        method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify({amount: 1000}),
    })
        .then(response => response.text())
        .then(text => {
            console.log(text);
            refreshData();
        });
}

function endVoting() {
    document.getElementById('startVoting').removeAttribute('disabled');
    document.getElementById('endVoting').setAttribute('disabled', '');

    fetch('http://localhost:3000/end-voting', {method: 'POST'})
        .then(response => response.text())
        .then(text => {
            console.log(text);
            refreshData();
            getLastWinner();
        });
}

function addParticipant() {
    event.preventDefault();
    const address = document.getElementById('newParticipantAddress').value;
    const name = document.getElementById('newParticipantName').value;
    if (address.length === 0 || name.length === 0) {
        alert('Incomplete data!');
        return;
    }

    fetch('http://localhost:3000/add-participant', {
        method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify({address, name}),
    })
        .then(response => response.text())
        .then(text => {
            console.log(text);
            document.getElementById('newParticipantForm').reset();
            getParticipants();
        });
}

function addOption() {
    event.preventDefault();
    const name = document.getElementById('newOptionName').value;
    if (name.length === 0) {
        alert('Incomplete data!');
        return;
    }

    fetch('http://localhost:3000/add-option', {
        method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify({name}),
    })
        .then(response => response.text())
        .then(text => {
            console.log(text);
            document.getElementById('newOptionForm').reset();
            getOptions();
        });
}

function vote() {
    event.preventDefault();
    const input = event.target[0];
    const votes = input.value;
    const name = event.path[1].getElementsByTagName('span')[0].textContent;
    const position = options.findIndex(option => option === name);

    fetch('http://localhost:3000/vote', {
        method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify({position, votes}),
    })
        .then(response => response.text())
        .then(text => {
            console.log(text);
            input.value = null;
            refreshData();
        });
}
