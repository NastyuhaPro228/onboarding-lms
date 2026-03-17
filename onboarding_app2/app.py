from flask import Flask, render_template, request, redirect, url_for, flash, send_from_directory, jsonify, session

from functools import wraps
import os
from uuid import uuid4
from werkzeug.security import generate_password_hash, check_password_hash
from werkzeug.utils import secure_filename
# update_passwords.py
from werkzeug.security import generate_password_hash
import db

# Словарь с пользователями и их паролями
users = [
    {'email': 'admin@company.local', 'password': 'admin_hash'},
    {'email': 'trainer@company.local', 'password': 'trainer_hash'},
    {'email': 'emp1@company.local', 'password': 'emp1_hash'},
    {'email': 'emp2@company.local', 'password': 'emp2_hash'},
]

for user in users:
    hashed = generate_password_hash(user['password'])
    db.execute(
        "UPDATE users SET password_hash = %s WHERE email = %s",
        (hashed, user['email'])
    )
    print(f"Обновлен пароль для {user['email']}")

print("Готово! Теперь пароли захэшированы.")


app = Flask(__name__)
app.secret_key = "super_secret_key_change_me"  # поменяй на свой

# Папка для файлов ответов на практики
UPLOAD_PRACTICE_FOLDER = os.path.join("static", "uploads", "practice_answers")
os.makedirs(UPLOAD_PRACTICE_FOLDER, exist_ok=True)
app.config["UPLOAD_PRACTICE_FOLDER"] = UPLOAD_PRACTICE_FOLDER
# ==== Вспомогательные декораторы ====


def login_required(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        if "user_id" not in session:
            flash("Для доступа к этой странице нужно войти в систему.", "warning")
            return redirect(url_for("index"))
        return f(*args, **kwargs)
    return wrapper


def admin_required(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        if "user_id" not in session or session.get("role_code") != "admin":
            flash("Доступ к административной панели только для администраторов.", "danger")
            return redirect(url_for("index"))
        return f(*args, **kwargs)
    return wrapper


# ==== Текущий пользователь ====


def get_current_user():
    if "user_id" not in session:
        return None
    return {
        "id": session["user_id"],
        "first_name": session.get("first_name"),
        "last_name": session.get("last_name"),
        "role_code": session.get("role_code"),
    }


# ==== Главная ====


@app.route("/")
def index():
    user = get_current_user()

    courses = db.fetch_all(
        """
        SELECT c.id, c.code, c.title, c.description, c.created_at,
               u.first_name, u.last_name
        FROM courses c
        JOIN users u ON c.created_by = u.id
        WHERE c.is_active = 1
        ORDER BY c.created_at DESC
        """
    )

    enrollments = []
    if user:
        enrollments = db.fetch_all(
            """
            SELECT ce.course_id, ce.status
            FROM course_enrollments ce
            WHERE ce.user_id = %s
            """,
            (user["id"],)
        )

    enrollment_map = {e["course_id"]: e["status"] for e in enrollments}

    return render_template(
        "index.html",
        user=user,
        courses=courses,
        enrollment_map=enrollment_map
    )


# ==== Аутентификация ====


@app.route("/login", methods=["POST"])
def login():
    email = request.form.get("email")
    password = request.form.get("password")

    # Сначала находим пользователя по email
    user = db.fetch_one(
        """
        SELECT u.*, r.code AS role_code
        FROM users u
        JOIN roles r ON u.role_id = r.id
        WHERE u.email = %s AND u.is_active = 1
        """,
        (email,)
    )

    # Проверяем: нашли пользователя И пароль совпадает
    if user and check_password_hash(user["password_hash"], password):
        session["user_id"] = user["id"]
        session["first_name"] = user["first_name"]
        session["last_name"] = user["last_name"]
        session["role_code"] = user["role_code"]

        db.execute(
            "UPDATE users SET last_login_at = NOW() WHERE id = %s",
            (user["id"],)
        )

        flash("Вы успешно вошли в систему.", "success")
        return redirect(url_for("index"))
    else:
        flash("Неверный логин или пароль.", "danger")
        return redirect(url_for("index"))
@app.route("/logout")
def logout():
    session.clear()
    flash("Вы вышли из системы.", "info")
    return redirect(url_for("index"))


# ==== Страница курса: модули, уроки, материалы, прогресс ====


@app.route("/course/<int:course_id>")
@login_required
def course_detail(course_id):
    user = get_current_user()

    # 1. Информация о курсе
    course = db.fetch_one(
        """
        SELECT c.*,
               u.first_name AS author_first_name,
               u.last_name  AS author_last_name
        FROM courses c
        JOIN users u ON c.created_by = u.id
        WHERE c.id = %s
        """,
        (course_id,)
    )
    if not course:
        flash("Курс не найден.", "danger")
        return redirect(url_for("index"))

    # 2. Назначение курса текущему пользователю (если есть)
    enrollment = db.fetch_one(
        """
        SELECT *
        FROM course_enrollments
        WHERE course_id = %s AND user_id = %s
        """,
        (course_id, user["id"])
    )

    # 3. Модули курса
    modules = db.fetch_all(
        """
        SELECT *
        FROM course_modules
        WHERE course_id = %s
        ORDER BY sort_order, id
        """,
        (course_id,)
    )
    module_ids = [m["id"] for m in modules]

    # Если модулей нет — дальше просто отрисуем пустую структуру
    if module_ids:
        ids_tuple = tuple(module_ids)
    else:
        ids_tuple = tuple([-1])  # заглушка, чтобы IN () не упал

    # 4. Лекции (lessons) по модулям
    lessons = db.fetch_all(
        f"""
        SELECT *
        FROM lessons
        WHERE module_id IN ({",".join(["%s"] * len(ids_tuple))})
        ORDER BY sort_order, id
        """,
        ids_tuple
    )
    lessons_by_module = {}
    for l in lessons:
        lessons_by_module.setdefault(l["module_id"], []).append(l)

    # 5. Практики по модулям
    practices = db.fetch_all(
        f"""
        SELECT *
        FROM practices
        WHERE module_id IN ({",".join(["%s"] * len(ids_tuple))})
        ORDER BY sort_order, id
        """,
        ids_tuple
    )
    practices_by_module = {}
    for p in practices:
        practices_by_module.setdefault(p["module_id"], []).append(p)

    # 6. Тесты курса:
    #   - модульные (module_id = id модуля),
    #   - финальные (is_final = 1, module_id IS NULL)
    tests = db.fetch_all(
        """
        SELECT *
        FROM tests
        WHERE course_id = %s
        ORDER BY
            CASE WHEN module_id IS NULL THEN 1 ELSE 0 END,
            module_id,
            sort_order,
            id
        """,
        (course_id,)
    )

    tests_by_module = {}
    final_tests = []
    for t in tests:
        if t["module_id"]:
            tests_by_module.setdefault(t["module_id"], []).append(t)
        elif t.get("is_final"):
            final_tests.append(t)

    # 7. Прогресс по урокам (для расчёта % по курсу/модулям)
    lessons_progress = {}
    total_lessons = 0
    completed_lessons = 0

    if enrollment:
        progress_rows = db.fetch_all(
            """
            SELECT cp.lesson_id, cp.status, cp.progress_pct, l.module_id
            FROM course_progress cp
            JOIN lessons l ON cp.lesson_id = l.id
            WHERE cp.enrollment_id = %s
            """,
            (enrollment["id"],)
        )
        for row in progress_rows:
            lessons_progress[row["lesson_id"]] = row
            total_lessons += 1
            if row["status"] == "completed":
                completed_lessons += 1
    else:
        progress_rows = []

    course_progress_pct = 0
    if total_lessons > 0:
        course_progress_pct = round(completed_lessons * 100 / total_lessons)

    # === Новая логика: прогресс по практикам и тестам, доступность модулей ===

    # 1) Какие практики уже «сделаны» (есть хотя бы одна отправка от пользователя)
    practice_ids = [p["id"] for p in practices]
    practice_done_ids = set()
    if practice_ids:
        placeholders = ",".join(["%s"] * len(practice_ids))
        params = (user["id"],) + tuple(practice_ids)
        rows = db.fetch_all(
            f"""
            SELECT DISTINCT practice_id
            FROM practice_submissions
            WHERE user_id = %s
              AND practice_id IN ({placeholders})
            """,
            params
        )
        practice_done_ids = {row["practice_id"] for row in rows}

    # 2) Какие модульные тесты уже пройдены (есть попытка с is_passed = 1)
    test_ids = [t["id"] for t in tests if t.get("module_id")]
    passed_test_ids = set()
    if test_ids:
        placeholders = ",".join(["%s"] * len(test_ids))
        params = (user["id"],) + tuple(test_ids)
        rows = db.fetch_all(
            f"""
            SELECT test_id, MAX(is_passed) AS passed
            FROM test_attempts
            WHERE user_id = %s
              AND test_id IN ({placeholders})
            GROUP BY test_id
            """,
            params
        )
        passed_test_ids = {row["test_id"] for row in rows if row["passed"]}

    # 3) Доступность модулей: следующий модуль открывается,
    #    только если предыдущий полностью завершён
    modules_access = {}
    previous_modules_completed = True

    for m in modules:
        mid = m["id"]

        module_lectures = lessons_by_module.get(mid, [])
        module_practices = practices_by_module.get(mid, [])
        module_tests = tests_by_module.get(mid, [])

        # все лекции модуля завершены?
        if module_lectures:
            lessons_completed = all(
                (lessons_progress.get(lesson["id"]) or {}).get("status") == "completed"
                for lesson in module_lectures
            )
        else:
            lessons_completed = True

        # все практики модуля отправлены (есть submission)?
        if module_practices:
            practices_completed = all(
                p["id"] in practice_done_ids for p in module_practices
            )
        else:
            practices_completed = True

        # все модульные тесты пройдены (есть attempt с is_passed = 1)?
        if module_tests:
            tests_completed = all(
                t["id"] in passed_test_ids for t in module_tests
            )
        else:
            tests_completed = True

        is_completed = lessons_completed and practices_completed and tests_completed
        is_unlocked = previous_modules_completed

        modules_access[mid] = {
            "is_unlocked": is_unlocked,
            "is_completed": is_completed,
        }

        # если модуль не завершён — все следующие будут закрыты
        previous_modules_completed = previous_modules_completed and is_completed

    # 4) Все ли модули завершены (для доступа к финальным тестам)?
    all_modules_completed = False
    if modules_access:
        all_modules_completed = all(
            info["is_completed"] for info in modules_access.values()
        )

    return render_template(
        "course_detail.html",
        user=user,
        course=course,
        enrollment=enrollment,
        modules=modules,
        lessons_by_module=lessons_by_module,
        practices_by_module=practices_by_module,
        tests_by_module=tests_by_module,
        final_tests=final_tests,
        lessons_progress=lessons_progress,
        course_progress_pct=course_progress_pct,
        modules_access=modules_access,
        all_modules_completed=all_modules_completed,  # ← новый параметр
    )



# ==== Страница лекции ====


@app.route("/course/<int:course_id>/lesson/<int:lesson_id>")
@login_required
def lesson_detail(course_id, lesson_id):
    user = get_current_user()

    # Лекция + проверка принадлежности курсу
    lesson = db.fetch_one(
        """
        SELECT l.*, cm.course_id, cm.title AS module_title
        FROM lessons l
        JOIN course_modules cm ON l.module_id = cm.id
        WHERE l.id = %s AND cm.course_id = %s
        """,
        (lesson_id, course_id)
    )
    if not lesson:
        flash("Лекция не найдена для данного курса.", "danger")
        return redirect(url_for("course_detail", course_id=course_id))

    course = db.fetch_one("SELECT * FROM courses WHERE id = %s", (course_id,))
    if not course:
        flash("Курс не найден.", "danger")
        return redirect(url_for("index"))

    # Найдём назначение курса пользователю
    enrollment = db.fetch_one(
        """
        SELECT *
        FROM course_enrollments
        WHERE course_id = %s AND user_id = %s
        """,
        (course_id, user["id"])
    )

    progress = None
    if enrollment:
        progress = db.fetch_one(
            """
            SELECT *
            FROM course_progress
            WHERE enrollment_id = %s AND lesson_id = %s
            """,
            (enrollment["id"], lesson_id)
        )

    return render_template(
        "lesson_detail.html",
        user=user,
        course=course,
        lesson=lesson,
        enrollment=enrollment,
        progress=progress
    )


# ==== Страница практики ====


@app.route("/course/<int:course_id>/practice/<int:practice_id>")
@login_required
def practice_detail(course_id, practice_id):
    user = get_current_user()

    practice = db.fetch_one(
        """
        SELECT p.*, cm.course_id, cm.title AS module_title
        FROM practices p
        JOIN course_modules cm ON p.module_id = cm.id
        WHERE p.id = %s AND cm.course_id = %s
        """,
        (practice_id, course_id)
    )
    if not practice:
        flash("Практическое задание не найдено для данного курса.", "danger")
        return redirect(url_for("course_detail", course_id=course_id))

    course = db.fetch_one("SELECT * FROM courses WHERE id = %s", (course_id,))
    if not course:
        flash("Курс не найден.", "danger")
        return redirect(url_for("index"))

    # Последняя отправка пользователя по этой практике (если была)
    last_submission = db.fetch_one(
        """
        SELECT *
        FROM practice_submissions
        WHERE practice_id = %s AND user_id = %s
        ORDER BY submitted_at DESC, id DESC
        LIMIT 1
        """,
        (practice_id, user["id"])
    )

    return render_template(
        "practice_detail.html",
        user=user,
        course=course,
        practice=practice,
        last_submission=last_submission
    )

@app.route("/course/<int:course_id>/practice/<int:practice_id>/submit", methods=["POST"])
@login_required
def submit_practice(course_id, practice_id):
    user = get_current_user()

    # Проверяем, что практика принадлежит курсу
    practice = db.fetch_one(
        """
        SELECT p.*, cm.course_id, cm.title AS module_title
        FROM practices p
        JOIN course_modules cm ON p.module_id = cm.id
        WHERE p.id = %s AND cm.course_id = %s
        """,
        (practice_id, course_id)
    )
    if not practice:
        flash("Практическое задание не найдено для данного курса.", "danger")
        return redirect(url_for("course_detail", course_id=course_id))

    answer_text = (request.form.get("answer_text") or "").strip()
    file = request.files.get("answer_file")
    answer_file_url = None

    # Валидация: смотрим expected_answer_type
    expected_type = practice["expected_answer_type"]

    has_text = bool(answer_text)
    has_file = file and file.filename

    if expected_type == "text" and not has_text:
        flash("Для этого задания обязателен текстовый ответ.", "danger")
        return redirect(url_for("practice_detail", course_id=course_id, practice_id=practice_id))

    if expected_type == "file" and not has_file:
        flash("Для этого задания обязательно прикрепить файл.", "danger")
        return redirect(url_for("practice_detail", course_id=course_id, practice_id=practice_id))

    if expected_type == "text_or_file" and not (has_text or has_file):
        flash("Нужно заполнить текст или прикрепить файл (можно и то, и другое).", "danger")
        return redirect(url_for("practice_detail", course_id=course_id, practice_id=practice_id))

    # Если есть файл — сохраняем его
    if has_file:
        filename = secure_filename(file.filename)
        # Добавим к имени уникальный суффикс, чтобы не было коллизий
        unique_name = f"{uuid4().hex}_{filename}"
        save_path = os.path.join(app.config["UPLOAD_PRACTICE_FOLDER"], unique_name)
        file.save(save_path)

        # URL для доступа из браузера
        answer_file_url = "/" + os.path.join(app.config["UPLOAD_PRACTICE_FOLDER"], unique_name).replace("\\", "/")

    # Записываем отправку в БД
    db.execute(
        """
        INSERT INTO practice_submissions (
            practice_id,
            user_id,
            answer_text,
            answer_file_url,
            status
        )
        VALUES (%s, %s, %s, %s, 'submitted')
        """,
        (practice_id, user["id"], answer_text if answer_text else None, answer_file_url)
    )

    flash("Решение по практике отправлено на проверку.", "success")
    return redirect(url_for("practice_detail", course_id=course_id, practice_id=practice_id))



# ==== Отметка урока как пройденного ====


@app.route("/course/<int:course_id>/lesson/<int:lesson_id>/complete", methods=["POST"])
@login_required
def complete_lesson(course_id, lesson_id):
    user = get_current_user()

    # Проверяем, что курс и урок существуют и связаны
    lesson = db.fetch_one(
        """
        SELECT l.id, l.module_id, cm.course_id
        FROM lessons l
        JOIN course_modules cm ON l.module_id = cm.id
        WHERE l.id = %s AND cm.course_id = %s
        """,
        (lesson_id, course_id)
    )
    if not lesson:
        flash("Урок не найден для данного курса.", "danger")
        return redirect(url_for("course_detail", course_id=course_id))

    # Находим/создаём назначение курса
    enrollment = db.fetch_one(
        """
        SELECT *
        FROM course_enrollments
        WHERE course_id = %s AND user_id = %s
        """,
        (course_id, user["id"])
    )
    if not enrollment:
        enrollment_id = db.execute(
            """
            INSERT INTO course_enrollments (course_id, user_id, assigned_by, status, assigned_at)
            VALUES (%s, %s, %s, 'in_progress', NOW())
            """,
            (course_id, user["id"], user["id"])
        )
    else:
        enrollment_id = enrollment["id"]

    # Обновляем/создаём запись в course_progress
    existing = db.fetch_one(
        """
        SELECT id, status
        FROM course_progress
        WHERE enrollment_id = %s AND lesson_id = %s
        """,
        (enrollment_id, lesson_id)
    )

    if existing:
        db.execute(
            """
            UPDATE course_progress
            SET status = 'completed',
                progress_pct = 100,
                last_accessed_at = NOW(),
                completed_at = NOW()
            WHERE id = %s
            """,
            (existing["id"],)
        )
    else:
        db.execute(
            """
            INSERT INTO course_progress (enrollment_id, lesson_id, status, progress_pct,
                                         last_accessed_at, completed_at)
            VALUES (%s, %s, 'completed', 100, NOW(), NOW())
            """,
            (enrollment_id, lesson_id)
        )

    # Пересчитываем прогресс по курсу
    total_lessons_row = db.fetch_one(
        """
        SELECT COUNT(*) AS cnt
        FROM lessons l
        JOIN course_modules cm ON l.module_id = cm.id
        WHERE cm.course_id = %s
        """,
        (course_id,)
    )
    total_lessons = total_lessons_row["cnt"] if total_lessons_row else 0

    completed_lessons_row = db.fetch_one(
        """
        SELECT COUNT(*) AS cnt
        FROM course_progress cp
        WHERE cp.enrollment_id = %s AND cp.status = 'completed'
        """,
        (enrollment_id,)
    )
    completed_lessons = completed_lessons_row["cnt"] if completed_lessons_row else 0

    # Если все уроки завершены — отмечаем курс как завершённый
    if total_lessons > 0 and completed_lessons == total_lessons:
        db.execute(
            """
            UPDATE course_enrollments
            SET status = 'completed', completed_at = NOW()
            WHERE id = %s
            """,
            (enrollment_id,)
        )
        flash("Отлично! Вы завершили все уроки курса.", "success")
    else:
        db.execute(
            """
            UPDATE course_enrollments
            SET status = 'in_progress'
            WHERE id = %s
            """,
            (enrollment_id,)
        )
        flash("Урок отмечен как пройден.", "success")

    return redirect(url_for("lesson_detail", course_id=course_id, lesson_id=lesson_id))


# ==== Система тестирования ====


@app.route("/course/<int:course_id>/test/<int:test_id>", methods=["GET", "POST"])
@login_required
def start_test(course_id, test_id):
    """
    Запуск конкретного теста курса (модульный / финальный).
    Соответствует ссылкам start_test в шаблоне course_detail.html и форме в test.html.
    """
    user = get_current_user()

    course = db.fetch_one(
        "SELECT * FROM courses WHERE id = %s",
        (course_id,)
    )
    if not course:
        flash("Курс не найден.", "danger")
        return redirect(url_for("index"))

    # Берём конкретный тест по ID и course_id
    test = db.fetch_one(
        """
        SELECT *
        FROM tests
        WHERE id = %s AND course_id = %s AND is_active = 1
        """,
        (test_id, course_id)
    )
    if not test:
        flash("Тест не найден или не активен для этого курса.", "info")
        return redirect(url_for("course_detail", course_id=course_id))

    questions = db.fetch_all(
        """
        SELECT *
        FROM test_questions
        WHERE test_id = %s
        ORDER BY sort_order, id
        """,
        (test["id"],)
    )

    q_ids = [q["id"] for q in questions]
    answers_by_question = {}

    if q_ids:
        placeholders = ",".join(["%s"] * len(q_ids))
        answers = db.fetch_all(
            f"""
            SELECT *
            FROM test_answers
            WHERE question_id IN ({placeholders})
            ORDER BY question_id, sort_order, id
            """,
            q_ids
        )
        for a in answers:
            answers_by_question.setdefault(a["question_id"], []).append(a)

    if request.method == "GET":
        return render_template(
            "test.html",
            user=user,
            course=course,
            test=test,
            questions=questions,
            answers_by_question=answers_by_question
        )

    # POST: проверка ответов и запись попытки

    # Обеспечиваем наличие записи в course_enrollments
    enrollment = db.fetch_one(
        """
        SELECT *
        FROM course_enrollments
        WHERE course_id = %s AND user_id = %s
        """,
        (course_id, user["id"])
    )
    if not enrollment:
        enrollment_id = db.execute(
            """
            INSERT INTO course_enrollments (course_id, user_id, assigned_by, status)
            VALUES (%s, %s, %s, 'in_progress')
            """,
            (course_id, user["id"], user["id"])
        )
    else:
        enrollment_id = enrollment["id"]

    # Создаём попытку
    attempt_id = db.execute(
        """
        INSERT INTO test_attempts (test_id, user_id, enrollment_id, started_at)
        VALUES (%s, %s, %s, NOW())
        """,
        (test["id"], user["id"], enrollment_id)
    )

    total_score = 0.0
    max_score = 0.0

    for q in questions:
        q_id = q["id"]
        max_score += float(q["score"])

        field_name = f"q_{q_id}"
        selected_answer_id = request.form.get(field_name)
        is_correct = 0

        if selected_answer_id:
            ans = db.fetch_one(
                "SELECT * FROM test_answers WHERE id = %s AND question_id = %s",
                (selected_answer_id, q_id)
            )
            if ans:
                if ans["is_correct"]:
                    is_correct = 1
                    total_score += float(q["score"])

            db.execute(
                """
                INSERT INTO test_attempt_answers (attempt_id, question_id, answer_id, is_correct)
                VALUES (%s, %s, %s, %s)
                """,
                (attempt_id, q_id, selected_answer_id, is_correct)
            )
        else:
            db.execute(
                """
                INSERT INTO test_attempt_answers (attempt_id, question_id, answer_id, is_correct)
                VALUES (%s, %s, NULL, 0)
                """,
                (attempt_id, q_id)
            )

    percent = 0.0
    if max_score > 0:
        percent = round(100.0 * total_score / max_score, 2)

    is_passed = 1 if percent >= test["passing_score"] else 0

    db.execute(
        """
        UPDATE test_attempts
        SET finished_at = NOW(),
            score_raw = %s,
            score_percent = %s,
            is_passed = %s
        WHERE id = %s
        """,
        (total_score, percent, is_passed, attempt_id)
    )

    if is_passed:
        db.execute(
            """
            UPDATE course_enrollments
            SET status = 'completed', completed_at = NOW()
            WHERE id = %s
            """,
            (enrollment_id,)
        )
        flash(f"Тест пройден! Результат: {percent}%.", "success")
    else:
        db.execute(
            """
            UPDATE course_enrollments
            SET status = 'in_progress'
            WHERE id = %s
            """,
            (enrollment_id,)
        )
        flash(
            f"Тест не пройден. Результат: {percent}%. "
            f"Нужно {test['passing_score']}% для зачёта.",
            "warning"
        )

    return redirect(url_for("course_detail", course_id=course_id))


# ==== Профиль пользователя и прогресс ====


@app.route("/profile")
@login_required
def profile():
    user = get_current_user()

    enrollments = db.fetch_all(
        """
        SELECT ce.*, c.title, c.description
        FROM course_enrollments ce
        JOIN courses c ON ce.course_id = c.id
        WHERE ce.user_id = %s
        ORDER BY ce.assigned_at DESC
        """,
        (user["id"],)
    )

    # Для каждого курса — лучший результат теста и прогресс по урокам
    for e in enrollments:
        # Лучший результат теста
        best = db.fetch_one(
            """
            SELECT MAX(ta.score_percent) AS best_score
            FROM test_attempts ta
            JOIN tests t ON ta.test_id = t.id
            WHERE ta.user_id = %s AND t.course_id = %s
            """,
            (user["id"], e["course_id"])
        )
        e["best_score"] = best["best_score"] if best and best["best_score"] is not None else None

        # Прогресс по урокам
        total_lessons_row = db.fetch_one(
            """
            SELECT COUNT(*) AS cnt
            FROM lessons l
            JOIN course_modules cm ON l.module_id = cm.id
            WHERE cm.course_id = %s
            """,
            (e["course_id"],)
        )
        total_lessons = total_lessons_row["cnt"] if total_lessons_row else 0

        completed_lessons_row = db.fetch_one(
            """
            SELECT COUNT(*) AS cnt
            FROM course_progress cp
            WHERE cp.enrollment_id = %s AND cp.status = 'completed'
            """,
            (e["id"],)
        )
        completed_lessons = completed_lessons_row["cnt"] if completed_lessons_row else 0

        if total_lessons > 0:
            e["progress_percent"] = round(100.0 * completed_lessons / total_lessons)
        else:
            e["progress_percent"] = None

        e["total_lessons"] = total_lessons
        e["completed_lessons"] = completed_lessons

    return render_template(
        "profile.html",
        user=user,
        enrollments=enrollments
    )


# ==== Админка ====


@app.route("/admin", methods=["GET"])
@admin_required
def admin_panel():
    user = get_current_user()

    # Все пользователи
    users = db.fetch_all(
        """
        SELECT u.id, u.email, u.first_name, u.last_name,
               r.code AS role_code, r.name AS role_name, u.is_active
        FROM users u
        JOIN roles r ON u.role_id = r.id
        ORDER BY u.id
        """
    )

    # Роли
    roles = db.fetch_all("SELECT * FROM roles ORDER BY id")

    # Курсы
    courses = db.fetch_all(
        """
        SELECT c.*, u.first_name, u.last_name
        FROM courses c
        JOIN users u ON c.created_by = u.id
        ORDER BY c.id
        """
    )

    # Админы / методисты (авторы курсов)
    admins = db.fetch_all(
        """
        SELECT u.id, CONCAT(u.last_name, ' ', u.first_name) AS full_name
        FROM users u
        JOIN roles r ON u.role_id = r.id
        WHERE r.code IN ('admin','methodist')
        ORDER BY u.last_name, u.first_name
        """
    )

    # Модули по всем курсам
    modules = db.fetch_all(
        """
        SELECT *
        FROM course_modules
        ORDER BY course_id, sort_order, id
        """
    )
    modules_by_course = {}
    for m in modules:
        modules_by_course.setdefault(m["course_id"], []).append(m)

    # ===== НОВОЕ: лекции и практики по модулям =====
    lessons = db.fetch_all(
        """
        SELECT *
        FROM lessons
        ORDER BY module_id, sort_order, id
        """
    )
    lessons_by_module = {}
    for l in lessons:
        lessons_by_module.setdefault(l["module_id"], []).append(l)

    practices = db.fetch_all(
        """
        SELECT *
        FROM practices
        ORDER BY module_id, sort_order, id
        """
    )
    practices_by_module = {}
    for p in practices:
        practices_by_module.setdefault(p["module_id"], []).append(p)
    # ==============================================

    # Тесты по всем курсам
    tests = db.fetch_all(
        """
        SELECT *
        FROM tests
        ORDER BY course_id, id
        """
    )
    tests_by_course = {}
    for t in tests:
        tests_by_course.setdefault(t["course_id"], []).append(t)

    # Вопросы ко всем тестам
    questions = db.fetch_all(
        """
        SELECT *
        FROM test_questions
        ORDER BY test_id, sort_order, id
        """
    )
    questions_by_test = {}
    for q in questions:
        questions_by_test.setdefault(q["test_id"], []).append(q)

    # Ответы ко всем вопросам
    answers = db.fetch_all(
        """
        SELECT *
        FROM test_answers
        ORDER BY question_id, sort_order, id
        """
    )
    answers_by_question = {}
    for a in answers:
        answers_by_question.setdefault(a["question_id"], []).append(a)

    # Сотрудники для назначения курсов
    employees = db.fetch_all(
        """
        SELECT u.id,
               CONCAT(u.last_name, ' ', u.first_name) AS full_name,
               r.code AS role_code
        FROM users u
        JOIN roles r ON u.role_id = r.id
        WHERE r.code = 'employee'
        ORDER BY u.last_name, u.first_name
        """
    )
    selected_user_id = request.args.get("selected_user_id", type=int)
    selected_user = None
    assigned_courses = []
    available_courses = []

    if selected_user_id:
        selected_user = db.fetch_one(
            """
            SELECT u.id,
                   CONCAT(u.last_name, ' ', u.first_name) AS full_name
            FROM users u
            WHERE u.id = %s
            """,
            (selected_user_id,)
        )

        assigned_courses = db.fetch_all(
            """
            SELECT ce.course_id,
                   c.title,
                   ce.status
            FROM course_enrollments ce
            JOIN courses c ON ce.course_id = c.id
            WHERE ce.user_id = %s
            ORDER BY c.title
            """,
            (selected_user_id,)
        )

        assigned_ids = {row["course_id"] for row in assigned_courses}
        # courses у тебя уже есть выше — просто фильтруем
        available_courses = [c for c in courses if c["id"] not in assigned_ids]

    return render_template(
        "admin_panel.html",
        user=user,
        users=users,
        roles=roles,
        courses=courses,
        admins=admins,
        modules_by_course=modules_by_course,
        tests_by_course=tests_by_course,
        questions_by_test=questions_by_test,
        answers_by_question=answers_by_question,
        employees=employees,
        # новые структуры для контент-редактора
        lessons_by_module=lessons_by_module,
        practices_by_module=practices_by_module,
        selected_user_id=selected_user_id,
        selected_user=selected_user,
        assigned_courses=assigned_courses,
        available_courses=available_courses,
    )
@app.route("/admin/module/<int:module_id>/reorder_item", methods=["POST"])
@admin_required
def admin_reorder_module_item(module_id):
    item_type = request.form.get("item_type")
    item_id = request.form.get("item_id", type=int)
    direction = request.form.get("direction", "up")

    if not item_type or not item_id:
        return jsonify({"success": False, "error": "Missing parameters"}), 400

    if item_type == "lesson":
        table = "lessons"
    elif item_type == "practice":
        table = "practices"
    elif item_type == "test":
        table = "tests"
    else:
        return jsonify({"success": False, "error": "Unknown item_type"}), 400

    # Текущий элемент
    row = db.fetch_one(
        f"SELECT id, sort_order FROM {table} WHERE id = %s AND module_id = %s",
        (item_id, module_id),
    )
    if not row:
        return jsonify({"success": False, "error": "Item not found"}), 404

    current_order = row["sort_order"]

    if direction == "up":
        neighbor = db.fetch_one(
            f"""
            SELECT id, sort_order
            FROM {table}
            WHERE module_id = %s AND sort_order < %s
            ORDER BY sort_order DESC, id DESC
            LIMIT 1
            """,
            (module_id, current_order),
        )
    else:  # down
        neighbor = db.fetch_one(
            f"""
            SELECT id, sort_order
            FROM {table}
            WHERE module_id = %s AND sort_order > %s
            ORDER BY sort_order ASC, id ASC
            LIMIT 1
            """,
            (module_id, current_order),
        )

    if not neighbor:
        # Нет соседнего элемента — ничего не меняем
        return jsonify({"success": True, "no_change": True})

    neighbor_id = neighbor["id"]
    neighbor_order = neighbor["sort_order"]

    # Меняем местами sort_order
    db.execute(
        f"UPDATE {table} SET sort_order = %s WHERE id = %s",
        (neighbor_order, item_id),
    )
    db.execute(
        f"UPDATE {table} SET sort_order = %s WHERE id = %s",
        (current_order, neighbor_id),
    )

    return jsonify({"success": True})



@app.route("/admin/lesson/<int:lesson_id>/update", methods=["POST"])
@admin_required
def admin_update_lesson(lesson_id):
    title = (request.form.get("title") or "").strip()
    description = request.form.get("description")
    video_url = request.form.get("video_url")
    attachment_url = request.form.get("attachment_url")
    sort_order = request.form.get("sort_order") or 1
    is_active = 1 if request.form.get("is_active") == "on" else 0

    db.execute(
        """
        UPDATE lessons
        SET title = %s,
            description = %s,
            video_url = %s,
            attachment_url = %s,
            sort_order = %s,
            is_active = %s
        WHERE id = %s
        """,
        (title, description, video_url, attachment_url, sort_order, is_active, lesson_id),
    )

    flash("Лекция обновлена.", "success")
    return redirect(url_for("admin_panel"))



@app.route("/admin/practice/<int:practice_id>", methods=["POST"])
@admin_required
def admin_update_practice(practice_id):
    """Обновление практики из модального окна редактирования."""
    title = request.form.get("title")
    description = request.form.get("description")
    task_text = request.form.get("task_text")
    task_file_url = request.form.get("task_file_url")
    expected_answer_type = request.form.get("expected_answer_type") or "text_or_file"
    sort_order = request.form.get("sort_order") or 1
    is_active = 1 if request.form.get("is_active") == "on" else 0

    db.execute(
        """
        UPDATE practices
        SET title = %s,
            description = %s,
            task_text = %s,
            task_file_url = %s,
            expected_answer_type = %s,
            sort_order = %s,
            is_active = %s
        WHERE id = %s
        """,
        (
            title,
            description,
            task_text,
            task_file_url,
            expected_answer_type,
            sort_order,
            is_active,
            practice_id,
        ),
    )
    flash("Практика обновлена.", "success")
    return redirect(url_for("admin_panel"))


@app.route("/admin/test/<int:test_id>", methods=["POST"])
@admin_required
def admin_update_test_simple(test_id):
    """Простое редактирование теста (заголовок/описание/порог/лимит/активность)."""
    test = db.fetch_one("SELECT course_id FROM tests WHERE id = %s", (test_id,))
    if not test:
        flash("Тест не найден.", "danger")
        return redirect(url_for("admin_panel"))

    title = request.form.get("title")
    description = request.form.get("description")
    passing_score = request.form.get("passing_score") or 70
    attempts_limit = request.form.get("attempts_limit") or None
    is_active = 1 if request.form.get("is_active") == "on" else 0
    sort_order = request.form.get("sort_order") or 1

    try:
        passing_score = int(passing_score)
    except ValueError:
        passing_score = 70

    if attempts_limit:
        try:
            attempts_limit = int(attempts_limit)
        except ValueError:
            attempts_limit = None

    try:
        sort_order = int(sort_order)
    except ValueError:
        sort_order = 1

    db.execute(
        """
        UPDATE tests
        SET title = %s,
            description = %s,
            passing_score = %s,
            attempts_limit = %s,
            is_active = %s,
            sort_order = %s
        WHERE id = %s
        """,
        (title, description, passing_score, attempts_limit, is_active, sort_order, test_id),
    )

    flash("Тест обновлён.", "success")
    return redirect(url_for("admin_panel"))



@app.route("/admin/course/<int:course_id>/test/<int:test_id>/question", methods=["POST"])
@admin_required
def admin_manage_question(course_id, test_id):
    action = request.form.get("action")

    # Проверим, что тест принадлежит курсу
    test = db.fetch_one(
        """
        SELECT id
        FROM tests
        WHERE id = %s AND course_id = %s
        """,
        (test_id, course_id)
    )
    if not test:
        flash("Тест не найден для указанного курса.", "danger")
        return redirect(url_for("admin_panel"))

    if action == "create":
        question_text = request.form.get("question_text")
        question_type = request.form.get("question_type") or "single_choice"
        score = request.form.get("score") or 1
        sort_order = request.form.get("sort_order") or 1

        try:
            score = float(score)
        except ValueError:
            score = 1.0

        try:
            sort_order = int(sort_order)
        except ValueError:
            sort_order = 1

        if not question_text:
            flash("Текст вопроса не может быть пустым.", "danger")
            return redirect(url_for("admin_panel"))

        db.execute(
            """
            INSERT INTO test_questions (test_id, question_text, question_type, score, sort_order)
            VALUES (%s, %s, %s, %s, %s)
            """,
            (test_id, question_text, question_type, score, sort_order)
        )
        flash("Вопрос добавлен.", "success")

    elif action == "update":
        question_id = request.form.get("question_id")
        question_text = request.form.get("question_text")
        question_type = request.form.get("question_type") or "single_choice"
        score = request.form.get("score") or 1
        sort_order = request.form.get("sort_order") or 1

        if not question_id:
            flash("Не удалось обновить вопрос: отсутствует ID.", "danger")
            return redirect(url_for("admin_panel"))

        try:
            score = float(score)
        except ValueError:
            score = 1.0

        try:
            sort_order = int(sort_order)
        except ValueError:
            sort_order = 1

        db.execute(
            """
            UPDATE test_questions
            SET question_text = %s,
                question_type = %s,
                score = %s,
                sort_order = %s
            WHERE id = %s AND test_id = %s
            """,
            (question_text, question_type, score, sort_order, question_id, test_id)
        )
        flash("Вопрос обновлён.", "success")

    elif action == "delete":
        question_id = request.form.get("question_id")
        if not question_id:
            flash("Не удалось удалить вопрос: отсутствует ID.", "danger")
            return redirect(url_for("admin_panel"))

        db.execute(
            """
            DELETE FROM test_questions
            WHERE id = %s AND test_id = %s
            """,
            (question_id, test_id)
        )
        flash("Вопрос удалён.", "info")

    else:
        flash("Неизвестное действие с вопросом.", "danger")

    return redirect(url_for("admin_panel"))


@app.route("/admin/course/<int:course_id>/test/<int:test_id>/answer", methods=["POST"])
@admin_required
def admin_manage_answer(course_id, test_id):
    action = request.form.get("action")

    # Проверим, что тест принадлежит курсу
    test = db.fetch_one(
        """
        SELECT id
        FROM tests
        WHERE id = %s AND course_id = %s
        """,
        (test_id, course_id)
    )
    if not test:
        flash("Тест не найден для указанного курса.", "danger")
        return redirect(url_for("admin_panel"))

    if action == "create":
        question_id = request.form.get("question_id")
        answer_text = request.form.get("answer_text")
        is_correct = 1 if request.form.get("is_correct") == "on" else 0
        sort_order = request.form.get("sort_order") or 1

        if not question_id or not answer_text:
            flash("Не удалось добавить ответ: нет текста или вопроса.", "danger")
            return redirect(url_for("admin_panel"))

        try:
            sort_order = int(sort_order)
        except ValueError:
            sort_order = 1

        db.execute(
            """
            INSERT INTO test_answers (question_id, answer_text, is_correct, sort_order)
            VALUES (%s, %s, %s, %s)
            """,
            (question_id, answer_text, is_correct, sort_order)
        )
        flash("Ответ добавлен.", "success")

    elif action == "update":
        answer_id = request.form.get("answer_id")
        answer_text = request.form.get("answer_text")
        is_correct = 1 if request.form.get("is_correct") == "on" else 0
        sort_order = request.form.get("sort_order") or 1

        if not answer_id:
            flash("Не удалось обновить ответ: отсутствует ID.", "danger")
            return redirect(url_for("admin_panel"))

        try:
            sort_order = int(sort_order)
        except ValueError:
            sort_order = 1

        db.execute(
            """
            UPDATE test_answers
            SET answer_text = %s,
                is_correct = %s,
                sort_order = %s
            WHERE id = %s
            """,
            (answer_text, is_correct, sort_order, answer_id)
        )
        flash("Ответ обновлён.", "success")

    elif action == "delete":
        answer_id = request.form.get("answer_id")
        if not answer_id:
            flash("Не удалось удалить ответ: отсутствует ID.", "danger")
            return redirect(url_for("admin_panel"))

        db.execute(
            """
            DELETE FROM test_answers
            WHERE id = %s
            """,
            (answer_id,)
        )
        flash("Ответ удалён.", "info")

    else:
        flash("Неизвестное действие с ответом.", "danger")

    return redirect(url_for("admin_panel"))


@app.route("/admin/course/<int:course_id>/modules", methods=["POST"])
@admin_required
def admin_manage_modules(course_id):
    action = request.form.get("action")

    if action == "create":
        title = request.form.get("title")
        description = request.form.get("description")
        sort_order = request.form.get("sort_order") or 1

        try:
            sort_order = int(sort_order)
        except ValueError:
            sort_order = 1

        if not title:
            flash("Название модуля не может быть пустым.", "danger")
            return redirect(url_for("admin_panel"))

        db.execute(
            """
            INSERT INTO course_modules (course_id, title, description, sort_order)
            VALUES (%s, %s, %s, %s)
            """,
            (course_id, title, description, sort_order)
        )
        flash("Модуль добавлен.", "success")

    elif action == "update":
        module_id = request.form.get("module_id")
        title = request.form.get("title")
        description = request.form.get("description")
        sort_order = request.form.get("sort_order") or 1

        try:
            sort_order = int(sort_order)
        except ValueError:
            sort_order = 1

        if not module_id or not title:
            flash("Не удалось обновить модуль: отсутствует ID или название.", "danger")
            return redirect(url_for("admin_panel"))

        db.execute(
            """
            UPDATE course_modules
            SET title = %s,
                description = %s,
                sort_order = %s
            WHERE id = %s AND course_id = %s
            """,
            (title, description, sort_order, module_id, course_id)
        )
        flash("Модуль обновлён.", "success")

    elif action == "delete":
        module_id = request.form.get("module_id")
        if not module_id:
            flash("Не удалось удалить модуль: отсутствует ID.", "danger")
            return redirect(url_for("admin_panel"))

        db.execute(
            """
            DELETE FROM course_modules
            WHERE id = %s AND course_id = %s
            """,
            (module_id, course_id)
        )
        flash("Модуль удалён.", "info")

    else:
        flash("Неизвестное действие с модулями.", "danger")

    return redirect(url_for("admin_panel"))


@app.route("/admin/course/<int:course_id>/test", methods=["POST"])
@admin_required
def admin_manage_test(course_id):
    action = request.form.get("action")

    if action == "create":
        title = request.form.get("title")
        description = request.form.get("description")
        passing_score = request.form.get("passing_score") or 70
        attempts_limit = request.form.get("attempts_limit") or None
        is_active = 1 if request.form.get("is_active") == "on" else 0

        try:
            passing_score = int(passing_score)
        except ValueError:
            passing_score = 70

        if attempts_limit:
            try:
                attempts_limit = int(attempts_limit)
            except ValueError:
                attempts_limit = None

        if not title:
            flash("Название теста не может быть пустым.", "danger")
            return redirect(url_for("admin_panel"))

        db.execute(
            """
            INSERT INTO tests (course_id, module_id, title, description,
                               passing_score, attempts_limit, is_active)
            VALUES (%s, NULL, %s, %s, %s, %s, %s)
            """,
            (course_id, title, description, passing_score, attempts_limit, is_active)
        )
        flash("Тест создан.", "success")

    elif action == "update":
        test_id = request.form.get("test_id")
        title = request.form.get("title")
        description = request.form.get("description")
        passing_score = request.form.get("passing_score") or 70
        attempts_limit = request.form.get("attempts_limit") or None
        is_active = 1 if request.form.get("is_active") == "on" else 0

        if not test_id:
            flash("Не удалось обновить тест: отсутствует ID.", "danger")
            return redirect(url_for("admin_panel"))

        try:
            passing_score = int(passing_score)
        except ValueError:
            passing_score = 70

        if attempts_limit:
            try:
                attempts_limit = int(attempts_limit)
            except ValueError:
                attempts_limit = None

        db.execute(
            """
            UPDATE tests
            SET title = %s,
                description = %s,
                passing_score = %s,
                attempts_limit = %s,
                is_active = %s
            WHERE id = %s AND course_id = %s
            """,
            (title, description, passing_score, attempts_limit, is_active, test_id, course_id)
        )
        flash("Тест обновлён.", "success")

    elif action == "delete":
        test_id = request.form.get("test_id")
        if not test_id:
            flash("Не удалось удалить тест: отсутствует ID.", "danger")
            return redirect(url_for("admin_panel"))

        db.execute(
            """
            DELETE FROM tests
            WHERE id = %s AND course_id = %s
            """,
            (test_id, course_id)
        )
        flash("Тест удалён.", "info")

    else:
        flash("Неизвестное действие с тестом.", "danger")

    return redirect(url_for("admin_panel"))


@app.route("/admin/assign_course", methods=["POST"])
@admin_required
def admin_assign_course():
    user_id = request.form.get("user_id")
    course_id = request.form.get("course_id")
    status = request.form.get("status") or "assigned"

    if not user_id or not course_id:
        flash("Не выбран пользователь или курс для назначения.", "danger")
        return redirect(url_for("admin_panel"))

    # Проверим, существует ли уже назначение
    existing = db.fetch_one(
        """
        SELECT id
        FROM course_enrollments
        WHERE user_id = %s AND course_id = %s
        """,
        (user_id, course_id)
    )

    if existing:
        db.execute(
            """
            UPDATE course_enrollments
            SET status = %s
            WHERE id = %s
            """,
            (status, existing["id"])
        )
        flash("Назначение курса пользователю обновлено.", "success")
    else:
        db.execute(
            """
            INSERT INTO course_enrollments (course_id, user_id, assigned_by, status, assigned_at)
            VALUES (%s, %s, %s, %s, NOW())
            """,
            (course_id, user_id, session.get("user_id"), status)
        )
        flash("Курс назначен пользователю.", "success")

    return redirect(url_for("admin_panel", selected_user_id=user_id))
@app.route("/admin/unassign_course", methods=["POST"])
@admin_required
def admin_unassign_course():
    @app.route("/admin/unassign_course", methods=["POST"])
    @admin_required
    def admin_unassign_course():
        user_id = request.form.get("user_id")
        course_id = request.form.get("course_id")

        if not user_id or not course_id:
            flash("Не выбран пользователь или курс для удаления назначения.", "danger")
            return redirect(url_for("admin_panel"))

        db.execute(
            """
            DELETE FROM course_enrollments
            WHERE user_id = %s AND course_id = %s
            """,
            (user_id, course_id)
        )

        flash("Пользователь отписан от курса.", "success")
        return redirect(url_for("admin_panel", selected_user_id=user_id))


@app.route("/admin/practice_submissions")
@admin_required
def admin_practice_submissions():
    """Страница со списком всех отправленных решений"""
    user = get_current_user()

    submissions = db.fetch_all("""
        SELECT ps.*, 
               p.title AS practice_title,
               u.first_name, u.last_name,
               c.title AS course_title,
               cm.title AS module_title
        FROM practice_submissions ps
        JOIN practices p ON ps.practice_id = p.id
        JOIN course_modules cm ON p.module_id = cm.id
        JOIN courses c ON cm.course_id = c.id
        JOIN users u ON ps.user_id = u.id
        WHERE ps.status = 'submitted'
        ORDER BY ps.submitted_at DESC
    """)

    return render_template("admin_submissions.html",
                           user=user,
                           submissions=submissions)


@app.route("/admin/practice/<int:submission_id>/review")
@admin_required
def admin_review_practice(submission_id):
    """Страница просмотра конкретного решения"""
    user = get_current_user()

    submission = db.fetch_one("""
        SELECT ps.*, 
               p.title AS practice_title, p.task_text,
               u.first_name, u.last_name, u.email,
               c.title AS course_title,
               cm.title AS module_title
        FROM practice_submissions ps
        JOIN practices p ON ps.practice_id = p.id
        JOIN course_modules cm ON p.module_id = cm.id
        JOIN courses c ON cm.course_id = c.id
        JOIN users u ON ps.user_id = u.id
        WHERE ps.id = %s
    """, (submission_id,))

    if not submission:
        flash("Решение не найдено", "danger")
        return redirect(url_for("admin_practice_submissions"))

    return render_template("admin_review.html",
                           user=user,
                           submission=submission)
    def admin_practice_submissions():
        """Страница со списком всех отправленных решений"""
        user = get_current_user()

        submissions = db.fetch_all("""
            SELECT ps.*, 
                   p.title AS practice_title,
                   u.first_name, u.last_name,
                   c.title AS course_title,
                   cm.title AS module_title
            FROM practice_submissions ps
            JOIN practices p ON ps.practice_id = p.id
            JOIN course_modules cm ON p.module_id = cm.id
            JOIN courses c ON cm.course_id = c.id
            JOIN users u ON ps.user_id = u.id
            WHERE ps.status = 'submitted'
            ORDER BY ps.submitted_at DESC
        """)

        return render_template("admin_submissions.html",
                               user=user,
                               submissions=submissions)

    @app.route("/admin/practice/<int:submission_id>/review")
    @admin_required
    def admin_review_practice(submission_id):
        """Страница просмотра конкретного решения"""
        user = get_current_user()

        submission = db.fetch_one("""
            SELECT ps.*, 
                   p.title AS practice_title, p.task_text,
                   u.first_name, u.last_name, u.email,
                   c.title AS course_title,
                   cm.title AS module_title
            FROM practice_submissions ps
            JOIN practices p ON ps.practice_id = p.id
            JOIN course_modules cm ON p.module_id = cm.id
            JOIN courses c ON cm.course_id = c.id
            JOIN users u ON ps.user_id = u.id
            WHERE ps.id = %s
        """, (submission_id,))

        if not submission:
            flash("Решение не найдено", "danger")
            return redirect(url_for("admin_practice_submissions"))

        return render_template("admin_review.html",
                               user=user,
                               submission=submission)
    def admin_practice_submissions():
        """Страница со списком всех отправленных решений"""
        user = get_current_user()

        submissions = db.fetch_all("""
            SELECT ps.*, 
                   p.title AS practice_title,
                   u.first_name, u.last_name,
                   c.title AS course_title,
                   cm.title AS module_title
            FROM practice_submissions ps
            JOIN practices p ON ps.practice_id = p.id
            JOIN course_modules cm ON p.module_id = cm.id
            JOIN courses c ON cm.course_id = c.id
            JOIN users u ON ps.user_id = u.id
            WHERE ps.status = 'submitted'
            ORDER BY ps.submitted_at DESC
        """)

        return render_template("admin_submissions.html",
                               user=user,
                               submissions=submissions)
    return redirect(url_for("admin_panel", selected_user_id=user_id))


@app.route("/admin/create_user", methods=["POST"])
@admin_required
def admin_create_user():
    email = request.form.get("email")
    password = request.form.get("password")
    first_name = request.form.get("first_name")
    last_name = request.form.get("last_name")
    role_id = request.form.get("role_id")

    existing = db.fetch_one("SELECT id FROM users WHERE email = %s", (email,))
    if existing:
        flash("Пользователь с таким email уже существует.", "danger")
        return redirect(url_for("admin_panel"))

    # Хэшируем пароль перед сохранением!
    hashed_password = generate_password_hash(password)

    db.execute(
        """
        INSERT INTO users (role_id, email, password_hash, first_name, last_name, is_active)
        VALUES (%s, %s, %s, %s, %s, 1)
        """,
        (role_id, email, hashed_password, first_name, last_name)
    )

    flash("Пользователь создан.", "success")
    return redirect(url_for("admin_panel"))

@app.route("/admin/toggle_user/<int:user_id>")
@admin_required
def admin_toggle_user(user_id):
    user = db.fetch_one("SELECT is_active FROM users WHERE id = %s", (user_id,))
    if not user:
        flash("Пользователь не найден.", "danger")
        return redirect(url_for("admin_panel"))

    new_status = 0 if user["is_active"] else 1
    db.execute("UPDATE users SET is_active = %s WHERE id = %s", (new_status, user_id))

    flash("Статус пользователя обновлён.", "success")
    return redirect(url_for("admin_panel"))


@app.route("/admin/create_course", methods=["POST"])
@admin_required
def admin_create_course():
    code = request.form.get("code")
    title = request.form.get("title")
    description = request.form.get("description")
    created_by = request.form.get("created_by")

    existing = db.fetch_one("SELECT id FROM courses WHERE code = %s", (code,))
    if existing:
        flash("Курс с таким кодом уже существует.", "danger")
        return redirect(url_for("admin_panel"))

    db.execute(
        """
        INSERT INTO courses (code, title, description, created_by, is_active, created_at)
        VALUES (%s, %s, %s, %s, 1, NOW())
        """,
        (code, title, description, created_by)
    )

    flash("Курс создан.", "success")
    return redirect(url_for("admin_panel"))


@app.route("/admin/update_course/<int:course_id>", methods=["POST"])
@admin_required
def admin_update_course(course_id):
    title = request.form.get("title")
    description = request.form.get("description")
    is_active = 1 if request.form.get("is_active") == "on" else 0

    db.execute(
        """
        UPDATE courses
        SET title = %s, description = %s, is_active = %s
        WHERE id = %s
        """,
        (title, description, is_active, course_id)
    )

    flash("Курс обновлён.", "success")
    return redirect(url_for("admin_panel"))


@app.route("/admin/delete_course/<int:course_id>", methods=["POST"])
@admin_required
def admin_delete_course(course_id):
    db.execute("DELETE FROM courses WHERE id = %s", (course_id,))
    flash("Курс удалён.", "info")
    return redirect(url_for("admin_panel"))

@app.errorhandler(404)
def page_not_found(e):
    flash("Страница не найдена. Проверьте адрес.", "warning")
    return redirect(url_for("index"))

@app.errorhandler(500)
def internal_server_error(e):
    flash("Произошла внутренняя ошибка. Мы уже знаем о проблеме.", "danger")
    return redirect(url_for("index"))

if __name__ == "__main__":
    app.run(debug=True)
