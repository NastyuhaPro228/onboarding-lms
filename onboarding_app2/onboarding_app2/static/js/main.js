// static/js/main.js

function openLoginModal() {
    const modal = document.getElementById('login-modal');
    if (modal) {
        modal.classList.add('active');
    }
}

function closeLoginModal() {
    const modal = document.getElementById('login-modal');
    if (modal) {
        modal.classList.remove('active');
    }
}

// Закрытие модального окна по клику на фон
document.addEventListener('click', function (e) {
    const modal = document.getElementById('login-modal');
    if (!modal) return;

    if (e.target === modal) {
        closeLoginModal();
    }
});

// Закрытие по Esc
document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') {
        closeLoginModal();
    }
});
// static/js/main.js

// Общие функции для модальных окон
function openModal(id) {
    var modal = document.getElementById(id);
    if (modal) {
        modal.classList.add('active');
    }
}

function closeModal(id) {
    var modal = document.getElementById(id);
    if (modal) {
        modal.classList.remove('active');
    }
}

// Специальные функции для модального окна логина
function openLoginModal() {
    openModal('login-modal');
}

function closeLoginModal() {
    closeModal('login-modal');
}

// Закрытие модального окна по клику на фон
document.addEventListener('click', function (e) {
    if (e.target.classList && e.target.classList.contains('modal-overlay')) {
        e.target.classList.remove('active');
    }
});

// Закрытие по Esc
document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') {
        var opened = document.querySelectorAll('.modal-overlay.active');
        opened.forEach(function (modal) {
            modal.classList.remove('active');
        });
    }
});
