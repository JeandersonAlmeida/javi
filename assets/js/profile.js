// User dropdown menu functionality
document.addEventListener('DOMContentLoaded', function () {
    const dropdownButton = document.getElementById('user-dropdown-button');
    const dropdownMenu = document.getElementById('user-dropdown-menu');

    if (dropdownButton && dropdownMenu) {
        // Toggle dropdown on button click
        dropdownButton.addEventListener('click', function (e) {
            e.stopPropagation();
            dropdownMenu.classList.toggle('hidden');
        });

        // Close dropdown when clicking outside
        document.addEventListener('click', function (event) {
            if (!dropdownButton.contains(event.target) && !dropdownMenu.contains(event.target)) {
                dropdownMenu.classList.add('hidden');
            }
        });

        // Close dropdown when clicking on menu items
        const menuItems = dropdownMenu.querySelectorAll('a, button');
        menuItems.forEach(item => {
            item.addEventListener('click', function () {
                dropdownMenu.classList.add('hidden');
            });
        });
    }
});

// Handle logout event from LiveView
window.addEventListener('phx:logout', function () {
    // Create a form to submit the DELETE request
    const form = document.createElement('form');
    form.method = 'POST';
    form.action = '/sair';

    // Add the CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
    const csrfInput = document.createElement('input');
    csrfInput.type = 'hidden';
    csrfInput.name = '_csrf_token';
    csrfInput.value = csrfToken;
    form.appendChild(csrfInput);

    // Add the _method field to make it a DELETE request
    const methodInput = document.createElement('input');
    methodInput.type = 'hidden';
    methodInput.name = '_method';
    methodInput.value = 'DELETE';
    form.appendChild(methodInput);

    // Submit the form
    document.body.appendChild(form);
    form.submit();
}); 