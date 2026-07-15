const API_URL = '/api/employees';

// (GET)
async function fetchEmployees() {
    try {
        const response = await fetch(API_URL);
        const employees = await response.json();
        const listDiv = document.getElementById('employeeList');
        listDiv.innerHTML = '';
        if (employees.length === 0) {
            listDiv.innerHTML = '<p>No employees found.</p>';
            return;
        }

        employees.forEach(emp => {
            const card = document.createElement('div');
            card.className = 'employee-card';
            card.innerText = `${emp.name} - ${emp.role}`;
            listDiv.appendChild(card);
        });
    } catch (error) {
        console.error('Error fetching data:', error);
        document.getElementById('employeeList').innerHTML = '<p style="color:red;">Error connecting to backend.</p>';
    }
}

// POST
document.getElementById('employeeForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const name = document.getElementById('empName').value;
    const role = document.getElementById('empRole').value;

    try {
        const response = await fetch(API_URL, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name, role })
        });

        if (response.ok) {
            document.getElementById('empName').value = '';
            document.getElementById('empRole').value = '';
            fetchEmployees();
        } else {
            alert('Failed to add employee');
        }
    } catch (error) {
        console.error('Error adding employee:', error);
        alert('Error connecting to server');
    }
});

window.onload = fetchEmployees;
