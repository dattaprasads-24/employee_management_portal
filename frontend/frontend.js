async function fetchEmployees() {
    try {
        const response = await fetch('/api/employees');
        const data = await response.json();
        const statusDiv = document.getElementById('status');
        const listUl = document.getElementById('employee-list');
        statusDiv.innerText = "Connected to Backend & Database!";
        listUl.innerHTML = '';
        data.forEach(emp => {
            const li = document.createElement('li');
            li.innerText = `${emp.name} - ${emp.role}`;
            listUl.appendChild(li);
        });
    } catch (error) {
        document.getElementById('status').innerText = "Error connecting to backend.";
        console.error(error);
    }
}

window.onload = fetchEmployees;
