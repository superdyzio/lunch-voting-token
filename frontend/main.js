function refreshData() {
    getParticipants();
    getOptions();
    getMyBalance();
    getLastWinner();
}

function getParticipants() {
    fetch('http://localhost:3000/get-all-participant-names')
        .then(response => response.json())
        .then(participantNames => {
            document.getElementById('participantList').innerText = participantNames.length > 0 ? participantNames.join(', ') : 'No participants.';
        });
}

function getOptions() {
    console.log('get options');
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

function addParticipant() {
    event.preventDefault();
    const address = document.getElementById('newParticipantAddress').value;
    const name = document.getElementById('newParticipantName').value;
    if (address.length === 0 || name.length === 0) {
        alert('Niekompletne dane!');
        return;
    }

    fetch('http://localhost:3000/add-participant',{
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ address, name }),
    })
        .then(response => response.text())
        .then(() => {
            document.getElementById('newParticipantForm').reset();
            getParticipants();
        });
}