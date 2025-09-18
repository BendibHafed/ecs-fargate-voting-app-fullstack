async function loadChoices(pollId){
    const r = await fetch(`/api/polls/${pollId}/choices`) ;
    const choices = await r.json();
    const elem = document.getElementById(`choices-${pollId}`);
    // Clear any existing content inside <div> => renders fresh buttons. 
    elem.innerHTML = '';
    for(const c of choices){
        const btn = document.createElement('button');
        btn.textContent = `${c.text} - Votes: ${c.votes}`;
        btn.onclick = async () => {
            await fetch(`/api/polls/${pollId}/vote`, {
                method:'POST',
                headers:{'Content-Type':'application/json'},
                body: JSON.stringify({choice_id: c.id})
            });
            loadChoices(pollId);
        };
        elem.appendChild(btn);
    }
}

// DOMContentLoaded says wait until the HTML document is fully loaded
document.addEventListener("DOMContentLoaded", () => {
    const pollDivs = document.querySelectorAll("[id^='choices-']"); // ^= : means starts with.
    pollDivs.forEach(div => {
        const pollId = div.id.split("-")[1]; // Extract the numeric ID
        loadChoices(pollId); // Load choices for each poll
    });
});