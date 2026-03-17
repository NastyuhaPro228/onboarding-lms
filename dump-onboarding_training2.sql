-- MySQL dump 10.13  Distrib 8.4.7, for Win64 (x86_64)
--
-- Host: localhost    Database: onboarding_training
-- ------------------------------------------------------
-- Server version	8.4.7

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `course_enrollments`
--

DROP TABLE IF EXISTS `course_enrollments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `course_enrollments` (
  `id` int NOT NULL AUTO_INCREMENT,
  `course_id` int NOT NULL,
  `user_id` int NOT NULL COMMENT 'Сотрудник',
  `assigned_by` int DEFAULT NULL COMMENT 'Кто назначил курс',
  `assigned_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `status` enum('assigned','in_progress','completed','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'assigned',
  `completed_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_course_user` (`course_id`,`user_id`),
  KEY `fk_enroll_user` (`user_id`),
  KEY `fk_enroll_assigned_by` (`assigned_by`),
  CONSTRAINT `fk_enroll_assigned_by` FOREIGN KEY (`assigned_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_enroll_course` FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_enroll_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Назначение курсов сотрудникам';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `course_enrollments`
--

LOCK TABLES `course_enrollments` WRITE;
/*!40000 ALTER TABLE `course_enrollments` DISABLE KEYS */;
INSERT INTO `course_enrollments` VALUES (1,1,3,2,'2025-12-02 23:04:33','in_progress',NULL),(2,1,4,2,'2025-12-02 23:04:33','assigned',NULL),(3,1,1,1,'2025-12-02 23:22:29','completed','2025-12-03 13:18:33');
/*!40000 ALTER TABLE `course_enrollments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `course_modules`
--

DROP TABLE IF EXISTS `course_modules`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `course_modules` (
  `id` int NOT NULL AUTO_INCREMENT,
  `course_id` int NOT NULL,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `sort_order` int NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `fk_modules_course` (`course_id`),
  CONSTRAINT `fk_modules_course` FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Модули (разделы) курса';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `course_modules`
--

LOCK TABLES `course_modules` WRITE;
/*!40000 ALTER TABLE `course_modules` DISABLE KEYS */;
INSERT INTO `course_modules` VALUES (1,1,'Введение в сервис и стандарты компании','Что такое сервис, почему гости возвращаются и как стандарты помогают держать уровень обслуживания.',1),(2,1,'Психология гостя и этапы продаж','Кто наш гость, чего он боится и чего ожидает. Классическая структура продажи.',2),(3,1,'Выявление потребностей гостя','Как задавать вопросы, слушать и уточнять, чтобы понять истинную потребность гостя.',3),(4,1,'Презентация продукта и работа с выгодами','Как показывать продукт так, чтобы гость видел личную выгоду, а не просто набор характеристик.',4),(5,1,'Работа с возражениями','Как спокойно и уверенно обрабатывать сомнения и возражения гостей.',5),(6,1,'Завершение продажи и постсервис','Как корректно подвести гостя к решению, оформить продажу и сохранить долгосрочные отношения.',6);
/*!40000 ALTER TABLE `course_modules` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `course_progress`
--

DROP TABLE IF EXISTS `course_progress`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `course_progress` (
  `id` int NOT NULL AUTO_INCREMENT,
  `enrollment_id` int NOT NULL COMMENT 'Ссылка на назначение курса',
  `lesson_id` int NOT NULL,
  `status` enum('not_started','in_progress','completed') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'not_started',
  `progress_pct` tinyint unsigned NOT NULL DEFAULT '0' COMMENT '0–100 %',
  `last_accessed_at` datetime DEFAULT NULL,
  `completed_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_progress` (`enrollment_id`,`lesson_id`),
  KEY `fk_progress_lesson` (`lesson_id`),
  CONSTRAINT `fk_progress_enrollment` FOREIGN KEY (`enrollment_id`) REFERENCES `course_enrollments` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_progress_lesson` FOREIGN KEY (`lesson_id`) REFERENCES `lessons` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Прогресс сотрудников по урокам курса';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `course_progress`
--

LOCK TABLES `course_progress` WRITE;
/*!40000 ALTER TABLE `course_progress` DISABLE KEYS */;
INSERT INTO `course_progress` VALUES (1,3,1,'completed',100,'2025-12-03 13:18:33','2025-12-03 13:18:33'),(2,3,2,'completed',100,'2025-12-02 23:22:31','2025-12-02 23:22:31'),(3,3,3,'completed',100,'2025-12-02 23:22:33','2025-12-02 23:22:33'),(4,3,4,'completed',100,'2025-12-02 23:22:36','2025-12-02 23:22:36'),(5,3,5,'completed',100,'2025-12-02 23:22:38','2025-12-02 23:22:38'),(6,3,6,'completed',100,'2025-12-02 23:22:41','2025-12-02 23:22:41'),(7,3,7,'completed',100,'2025-12-02 23:22:44','2025-12-02 23:22:44'),(8,3,8,'completed',100,'2025-12-02 23:22:48','2025-12-02 23:22:48'),(9,3,9,'completed',100,'2025-12-02 23:22:51','2025-12-02 23:22:51'),(10,3,10,'completed',100,'2025-12-02 23:22:54','2025-12-02 23:22:54'),(11,3,11,'completed',100,'2025-12-02 23:22:58','2025-12-02 23:22:58'),(12,3,12,'completed',100,'2025-12-02 23:23:01','2025-12-02 23:23:01'),(13,1,1,'completed',100,'2025-12-03 00:48:34','2025-12-03 00:48:34');
/*!40000 ALTER TABLE `course_progress` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `courses`
--

DROP TABLE IF EXISTS `courses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `courses` (
  `id` int NOT NULL AUTO_INCREMENT,
  `code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Код курса для системы',
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Название курса',
  `description` text COLLATE utf8mb4_unicode_ci,
  `created_by` int NOT NULL COMMENT 'Автор (методист/админ)',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`),
  KEY `fk_courses_created_by` (`created_by`),
  CONSTRAINT `fk_courses_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Курсы для обучения сотрудников';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `courses`
--

LOCK TABLES `courses` WRITE;
/*!40000 ALTER TABLE `courses` DISABLE KEYS */;
INSERT INTO `courses` VALUES (1,'SALES_GUEST_SERVICE','Техники продаж и правила обслуживания гостей','Полноценный курс для подготовки нового сотрудника фронт-линии: стандарты сервиса, этапы продаж, работа с возражениями и постобслуживание гостей.',2,1,'2025-12-02 23:04:32',NULL),(2,'TEST_ONE','Тест','Тесттест',1,1,'2025-12-02 23:35:36',NULL);
/*!40000 ALTER TABLE `courses` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `departments`
--

DROP TABLE IF EXISTS `departments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `departments` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Название отдела',
  `description` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Отделы компании';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `departments`
--

LOCK TABLES `departments` WRITE;
/*!40000 ALTER TABLE `departments` DISABLE KEYS */;
INSERT INTO `departments` VALUES (1,'Отдел продаж','Отдел, который отвечает за привлечение и обслуживание клиентов'),(2,'Служба сервиса','Поддержка клиентов и работа с обращениями'),(3,'HR-отдел','Подбор, адаптация и обучение персонала');
/*!40000 ALTER TABLE `departments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `employee_profiles`
--

DROP TABLE IF EXISTS `employee_profiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `employee_profiles` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL COMMENT 'Ссылка на пользователя-сотрудника',
  `department_id` int DEFAULT NULL,
  `position_id` int DEFAULT NULL,
  `hire_date` date DEFAULT NULL COMMENT 'Дата приёма на работу',
  `mentor_id` int DEFAULT NULL COMMENT 'Наставник (другой пользователь)',
  `notes` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`),
  KEY `fk_emp_department` (`department_id`),
  KEY `fk_emp_position` (`position_id`),
  KEY `fk_emp_mentor` (`mentor_id`),
  CONSTRAINT `fk_emp_department` FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_emp_mentor` FOREIGN KEY (`mentor_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_emp_position` FOREIGN KEY (`position_id`) REFERENCES `positions` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_emp_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Профили сотрудников';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `employee_profiles`
--

LOCK TABLES `employee_profiles` WRITE;
/*!40000 ALTER TABLE `employee_profiles` DISABLE KEYS */;
INSERT INTO `employee_profiles` VALUES (1,3,1,4,'2025-11-01',2,'Стажёр в отделе продаж, проходит базовый курс по техникам продаж'),(2,4,1,3,'2025-10-15',2,'Менеджер по работе с гостями, планируется повышение до старшего менеджера');
/*!40000 ALTER TABLE `employee_profiles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `feedback`
--

DROP TABLE IF EXISTS `feedback`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `feedback` (
  `id` int NOT NULL AUTO_INCREMENT,
  `course_id` int NOT NULL,
  `user_id` int NOT NULL COMMENT 'Сотрудник',
  `rating` tinyint NOT NULL COMMENT 'Оценка 1–5',
  `comment` text COLLATE utf8mb4_unicode_ci,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_feedback_course` (`course_id`),
  KEY `fk_feedback_user` (`user_id`),
  CONSTRAINT `fk_feedback_course` FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_feedback_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Отзывы сотрудников о курсах';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `feedback`
--

LOCK TABLES `feedback` WRITE;
/*!40000 ALTER TABLE `feedback` DISABLE KEYS */;
INSERT INTO `feedback` VALUES (1,1,3,5,'Курс помог структурировать общение с гостями, стало проще завершать продажи и обрабатывать возражения.','2025-12-02 23:04:33');
/*!40000 ALTER TABLE `feedback` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `lesson_materials`
--

DROP TABLE IF EXISTS `lesson_materials`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `lesson_materials` (
  `id` int NOT NULL AUTO_INCREMENT,
  `lesson_id` int NOT NULL,
  `material_type` enum('text','file','link','video') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'text',
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `content` text COLLATE utf8mb4_unicode_ci COMMENT 'Текст или URL/путь к файлу',
  `sort_order` int NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `fk_materials_lesson` (`lesson_id`),
  CONSTRAINT `fk_materials_lesson` FOREIGN KEY (`lesson_id`) REFERENCES `lessons` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Материалы уроков';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lesson_materials`
--

LOCK TABLES `lesson_materials` WRITE;
/*!40000 ALTER TABLE `lesson_materials` DISABLE KEYS */;
INSERT INTO `lesson_materials` VALUES (1,1,'text','Конспект урока «Роль сервиса в бизнесе»','PDF-конспект: ключевые аргументы в пользу качественного сервиса, примеры хорошего и плохого сервиса, чек-лист «Какой сервис я даю гостям сегодня».',1),(2,2,'text','Чек-лист стандартов обслуживания','Список базовых стандартов: приветствие, представление, активное предложение помощи, подтверждение запроса, благодарность и прощание.',1),(3,3,'text','Типология гостей','Таблица с описанием основных типов гостей, их ожиданий и рекомендованной стратегии общения.',1),(4,4,'text','Схема этапов продаж','Графическая схема 6 этапов продаж с короткими подсказками по каждому шагу.',1),(5,5,'text','Памятка по вопросам','Примеры удачных открытых и закрытых вопросов для разных сценариев общения с гостями.',1),(6,6,'text','Шаблоны СПИН-вопросов','Набор заготовок ситуативных, проблемных, извлекающих и направляющих вопросов для разных продуктов.',1),(7,7,'text','Презентация через выгоды','Таблица «характеристика → выгода → подтверждение» для ключевых продуктов компании.',1),(8,8,'text','Сценарии демонстрации продукта','Описание сценариев демонстрации продукта в очном и дистанционном формате с рекомендациями по фразам.',1),(9,9,'text','Карта возражений','Список типовых возражений гостей с примерами уточняющих и поддерживающих фраз.',1),(10,10,'text','Алгоритм работы с возражениями','Пошаговый алгоритм с примерами фраз на каждом этапе: выслушать, уточнить, согласиться в части, аргументировать, проверить.',1),(11,11,'text','Фразы для завершения продажи','Подборка мягких и уверенных фраз для предложения перейти к оформлению решения.',1),(12,12,'text','Памятка по постсервису','Чек-лист действий после продажи: благодарность, фиксация договорённостей, следующие шаги, предложение обратной связи.',1);
/*!40000 ALTER TABLE `lesson_materials` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `lessons`
--

DROP TABLE IF EXISTS `lessons`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `lessons` (
  `id` int NOT NULL AUTO_INCREMENT,
  `module_id` int NOT NULL,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `content` text COLLATE utf8mb4_unicode_ci COMMENT 'Основной текст/контент урока (если храним прямо в БД)',
  `sort_order` int NOT NULL DEFAULT '1',
  `estimated_time` int DEFAULT NULL COMMENT 'Ожидаемое время прохождения, минут',
  PRIMARY KEY (`id`),
  KEY `fk_lessons_module` (`module_id`),
  CONSTRAINT `fk_lessons_module` FOREIGN KEY (`module_id`) REFERENCES `course_modules` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Уроки внутри модулей курса';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lessons`
--

LOCK TABLES `lessons` WRITE;
/*!40000 ALTER TABLE `lessons` DISABLE KEYS */;
INSERT INTO `lessons` VALUES (1,1,'Роль сервиса в бизнесе','Зачем компании качественный сервис и как он влияет на деньги, репутацию и атмосферу.','В этом уроке мы разбираем, почему сервис — это не «улыбка для галочки», а конкретные деньги компании.\r\nГость оценивает не только продукт, но и отношение, скорость реакции, готовность помочь. \r\nКачественный сервис:\r\n• повышает возвратность гостей;\r\n• снижает количество конфликтов;\r\n• уменьшает нагрузку на руководство;\r\n• формирует рекомендации «из уст в уста».',1,20),(2,1,'Стандарты обслуживания гостей','Что такое стандарты, зачем они нужны и как ими пользоваться на практике.','Стандарты обслуживания — это набор ожидаемых действий и формулировок, которые помогают всем сотрудникам работать в одном стиле.\r\nПримеры стандартов:\r\n• приветствие гостя в течение 30 секунд с момента появления;\r\n• представление по имени;\r\n• активное предложение помощи;\r\n• подтверждение запроса гостя своими словами;\r\n• завершение диалога с благодарностью.\r\nСтандарты не убивают индивидуальность, а задают минимальный гарантированный уровень сервиса.',2,25),(3,2,'Типы гостей и их ожидания','Основные типы гостей и то, чего они боятся и ждут от контакта с сотрудником.','Гостей условно можно разделить на несколько типов: рациональные, эмоциональные, спешащие, сомневающиеся, «знающие всё».\r\nУ каждого типа — свои ожидания:\r\n• рациональный — хочет структурированную информацию и аргументы;\r\n• эмоциональный — хочет эмоций и ощущения заботы;\r\n• спешащий — ценит скорость и чёткость;\r\n• сомневающийся — нуждается в поддержке и подтверждении выбора.\r\nЗадача сотрудника — за первые 1–2 минуты общения понять тип гостя и адаптировать стиль коммуникации.',1,25),(4,2,'Классические этапы продаж','От приветствия до постпродажного контакта: шаги, которые нельзя пропускать.','Классическая модель продаж включает следующие этапы:\r\n1. Установление контакта (приветствие, визуальный контакт, открывающий вопрос).\r\n2. Выявление потребностей (вопросы и активное слушание).\r\n3. Презентация решения (продукта/услуги) под потребность гостя.\r\n4. Работа с возражениями (снятие сомнений).\r\n5. Завершение продажи (предложение оформить решение).\r\n6. Постсервис (поддержание отношений, благодарность, приглашение вернуться).\r\nПропуск одного из этапов повышает риск отказа или недовольства гостя.',2,30),(5,3,'Открытые и закрытые вопросы','Какие вопросы помогают гостю раскрыться, а какие — «закрывают» диалог.','Открытые вопросы начинаются с «что», «как», «почему» и побуждают гостя рассказывать.\r\nЗакрытые вопросы предполагают ответ «да/нет» или короткую фразу.\r\nПримеры:\r\n• Открытые: «Расскажите, пожалуйста, что для вас важно при выборе...?», «Как вы планируете использовать...?»\r\n• Закрытые: «Вам удобно сегодня?», «Этот вариант подходит?»\r\nНа этапе выявления потребностей мы опираемся на открытые вопросы, а закрытыми уточняем детали.',1,25),(6,3,'Техника СПИН/ФОС в продажах','Как структурировать вопросы, чтобы гость сам увидел ценность решения.','СПИН — это модель построения вопросов:\r\nS (ситуационные) — про текущую ситуацию гостя;\r\nP (проблемные) — про сложности, с которыми он сталкивается;\r\nI (извлекающие) — про последствия этих проблем;\r\nN (направляющие) — подводят к необходимости решения.\r\nАналогично в русскоязычной практике используют аббревиатуры ФОС или СППВ, суть одна — плавно подвести гостя к осознанию важности изменений.',2,30),(7,4,'Презентация через выгоды, а не характеристики','Как говорить о продукте на языке пользы гостя.','Характеристика отвечает на вопрос «что это?», а выгода — «что это даёт лично гостю?».\r\nНапример:\r\n• Характеристика: «Эта программа обучения длится 2 недели».\r\n• Выгода: «Уже через 2 недели вы сможете увереннее общаться с гостями и закрывать больше продаж».\r\nПрезентация строится по формуле: характеристика → выгода → подтверждение (пример, кейс, отзыв).',1,25),(8,4,'Визуализация и демонстрация продукта','Почему гостю важно «увидеть» продукт до покупки.','Чем больше каналов восприятия задействовано (зрение, слух, тактильные ощущения), тем выше доверие к продукту.\r\nЕсли возможно — показываем примеры, интерфейс, образцы, демонстрацию «до/после».\r\nВажно комментировать демонстрацию, связывая её с потребностями гостя, которые мы уже выяснили.',2,20),(9,5,'Основные типы возражений','«Дорого», «Я подумаю», «Мне нужно посоветоваться» — что за ними стоит.','Большинство возражений можно отнести к нескольким группам:\r\n• финансовые («дорого», «нет бюджета»),\r\n• временные («не сейчас», «я подумаю»),\r\n• доверительные («я не уверен», «нужно посоветоваться»),\r\n• технические («подойдёт ли именно мне?»).\r\nВажно помнить: возражение — это не отказ, а сигнал, что гость ещё не видит достаточно ценности или ясности.',1,25),(10,5,'Алгоритм работы с возражениями','Пошаговый разбор: выслушать, уточнить, согласиться в части, дать аргумент.','Базовый алгоритм:\r\n1. Спокойно выслушать возражение, не перебивая.\r\n2. Уточнить суть: «Правильно ли я понимаю, что вам важно...?»\r\n3. Согласиться в части: признать право гостя сомневаться.\r\n4. Дать аргумент или альтернативу, связав её с потребностью.\r\n5. Проверить реакцию: «Как сейчас вам кажется?»\r\nЭтот алгоритм снижает напряжение и возвращает диалог в конструктивное русло.',2,30),(11,6,'Техники завершения продажи','Как корректно предложить оформить решение и не «сломать» доверие гостя.','Многие сотрудники боятся этапа завершения продажи, хотя к нему подводит вся предыдущая работа.\r\nПримеры мягких техник:\r\n• Альтернативный выбор: «Мы оформляем на месяц или сразу на квартал?»\r\n• Уточняющий: «Если по содержанию всё подходит, можем оформить прямо сейчас?»\r\n• Шаг вперёд: «Тогда я сейчас оформлю заявку, а вы пока посмотрите...»\r\nГлавное — говорить уверенно и доброжелательно, не давя на гостя.',1,25),(12,6,'Постсервис и долгосрочные отношения','Что делать после продажи, чтобы гость вернулся и рекомендовал нас другим.','Сервис не заканчивается в момент оплаты.\r\nВажно:\r\n• поблагодарить гостя и коротко закрепить результат («Сегодня вы сделали отличный шаг к...»),\r\n• обозначить дальнейшие шаги (контакты, сопровождение),\r\n• при необходимости — уточнить, удобно ли гостю получить напоминание/подборку рекомендаций позже.\r\nПостсервис формирует лояльность и даёт основу для повторных продаж.',2,20);
/*!40000 ALTER TABLE `lessons` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `positions`
--

DROP TABLE IF EXISTS `positions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `positions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Название должности',
  `description` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Должности сотрудников';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `positions`
--

LOCK TABLES `positions` WRITE;
/*!40000 ALTER TABLE `positions` DISABLE KEYS */;
INSERT INTO `positions` VALUES (1,'Руководитель отдела продаж','Отвечает за выполнение планов продаж и управление командой'),(2,'Тренер по продажам','Разрабатывает и проводит обучающие программы по продажам и сервису'),(3,'Менеджер по работе с гостями','Непосредственно общается с гостями и осуществляет продажи'),(4,'Стажёр отдела продаж','Новый сотрудник на этапе адаптации');
/*!40000 ALTER TABLE `positions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `practice_submissions`
--

DROP TABLE IF EXISTS `practice_submissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `practice_submissions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `practice_id` int NOT NULL,
  `user_id` int NOT NULL,
  `answer_text` longtext,
  `answer_file_url` varchar(500) DEFAULT NULL,
  `status` enum('submitted','under_review','approved','rejected') NOT NULL DEFAULT 'submitted',
  `reviewer_id` int DEFAULT NULL,
  `review_comment` text,
  `submitted_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `reviewed_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_submissions_practice` (`practice_id`),
  KEY `fk_submissions_user` (`user_id`),
  KEY `fk_submissions_reviewer` (`reviewer_id`),
  CONSTRAINT `fk_submissions_practice` FOREIGN KEY (`practice_id`) REFERENCES `practices` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_submissions_reviewer` FOREIGN KEY (`reviewer_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_submissions_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `practice_submissions`
--

LOCK TABLES `practice_submissions` WRITE;
/*!40000 ALTER TABLE `practice_submissions` DISABLE KEYS */;
/*!40000 ALTER TABLE `practice_submissions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `practices`
--

DROP TABLE IF EXISTS `practices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `practices` (
  `id` int NOT NULL AUTO_INCREMENT,
  `module_id` int NOT NULL,
  `title` varchar(255) NOT NULL,
  `description` text,
  `task_text` longtext,
  `task_file_url` varchar(500) DEFAULT NULL,
  `expected_answer_type` enum('text','file','text_or_file') NOT NULL DEFAULT 'text_or_file',
  `sort_order` int NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_practices_module` (`module_id`),
  CONSTRAINT `fk_practices_module` FOREIGN KEY (`module_id`) REFERENCES `course_modules` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `practices`
--

LOCK TABLES `practices` WRITE;
/*!40000 ALTER TABLE `practices` DISABLE KEYS */;
INSERT INTO `practices` VALUES (1,1,'Практика 1. Анализ ценностей компании','Ознакомьтесь с корпоративным кодексом. Составьте краткий конспект из 5–7 пунктов, описывающих ключевые ценности компании, и придумайте по одному жизненному примеру для каждой ценности.','123',NULL,'text_or_file',1,1,'2025-12-03 13:17:57','2025-12-03 14:04:04'),(2,1,'Практика 2. Маршрут нового сотрудника','Нарисуйте или опишите маршрут первого дня нового сотрудника: какие подразделения он посещает, с кем знакомится, какие документы оформляет. Отметьте, где могут возникнуть сложности и как их сгладить.',NULL,NULL,'text_or_file',2,1,'2025-12-03 13:17:57','2025-12-03 13:17:57'),(3,2,'Практика 3. Скрипт приветствия гостя','Составьте текст приветствия для гостя, который впервые обращается в компанию. Учтите: тон общения, обязательные вопросы, варианты вежливого завершения диалога.',NULL,NULL,'text_or_file',1,1,'2025-12-03 13:17:57','2025-12-03 13:17:57'),(4,2,'Практика 4. Работа с возражениями','Возьмите 3 типичных возражения клиентов (например: «Дорого», «Я подумаю», «Нашёл дешевле»). Для каждого разработайте по 2 корректных ответа, соответствующих стандартам компании.',NULL,NULL,'text_or_file',2,1,'2025-12-03 13:17:57','2025-12-03 13:17:57'),(5,3,'Практика 5. Внесение карточки клиента','Создайте тестовую карточку клиента в учебной версии CRM: заполните обязательные поля, добавьте заметку по результатам разговора, поставьте напоминание о следующем контакте.',NULL,NULL,'text_or_file',1,1,'2025-12-03 13:17:57','2025-12-03 13:17:57'),(6,3,'Практика 6. Фиксация задачи и отчётности','Создайте тестовую задачу на себя в системе учёта задач: корректно сформулируйте цель, укажите дедлайн и чек-лист действий. После «выполнения» закройте задачу и проверьте, как она отображается в отчётности.',NULL,NULL,'text_or_file',2,1,'2025-12-03 13:17:57','2025-12-03 13:17:57');
/*!40000 ALTER TABLE `practices` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `roles`
--

DROP TABLE IF EXISTS `roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `roles` (
  `id` int NOT NULL AUTO_INCREMENT,
  `code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Системное имя роли (admin, methodist, employee)',
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Отображаемое название роли',
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Роли пользователей';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `roles`
--

LOCK TABLES `roles` WRITE;
/*!40000 ALTER TABLE `roles` DISABLE KEYS */;
INSERT INTO `roles` VALUES (1,'admin','Администратор'),(2,'methodist','Методист / тренер'),(3,'employee','Сотрудник');
/*!40000 ALTER TABLE `roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `test_answers`
--

DROP TABLE IF EXISTS `test_answers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `test_answers` (
  `id` int NOT NULL AUTO_INCREMENT,
  `question_id` int NOT NULL,
  `answer_text` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_correct` tinyint(1) NOT NULL DEFAULT '0',
  `sort_order` int NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `fk_answers_question` (`question_id`),
  CONSTRAINT `fk_answers_question` FOREIGN KEY (`question_id`) REFERENCES `test_questions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=77 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Варианты ответов на вопросы тестов';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `test_answers`
--

LOCK TABLES `test_answers` WRITE;
/*!40000 ALTER TABLE `test_answers` DISABLE KEYS */;
INSERT INTO `test_answers` VALUES (1,1,'Создать красивую картинку для отчётов руководства.',0,1),(2,1,'Сделать так, чтобы гость чувствовал заботу и хотел возвращаться.',1,2),(3,1,'Минимизировать общение с гостями.',0,3),(4,1,'Сократить время обучения сотрудников.',0,4),(5,2,'Установление контакта → Презентация решения → Выявление потребностей → Работа с возражениями → Завершение продажи → Постсервис',0,1),(6,2,'Выявление потребностей → Установление контакта → Презентация решения → Завершение продажи → Работа с возражениями → Постсервис',0,2),(7,2,'Установление контакта → Выявление потребностей → Презентация решения → Работа с возражениями → Завершение продажи → Постсервис',1,3),(8,2,'Презентация решения → Завершение продажи → Постсервис → Установление контакта → Выявление потребностей → Работа с возражениями',0,4),(9,3,'«Вам удобно сейчас?»',0,1),(10,3,'«Вы уже бывали у нас раньше?»',0,2),(11,3,'«Расскажите, пожалуйста, что для вас важно при выборе услуги?»',1,3),(12,3,'«Этот вариант вас устраивает?»',0,4),(13,4,'Краткое перечисление характеристик продукта.',0,1),(14,4,'Сбор информации о том, чего гость боится и чего хочет, через вопросы и слушание.',1,2),(15,4,'Попытка как можно быстрее перейти к оформлению продажи.',0,3),(16,4,'Обсуждение условий оплаты.',0,4),(17,5,'Стандарты нужны только для новых сотрудников, опытные могут работать как привыкли.',0,1),(18,5,'Стандарты задают минимальный уровень сервиса и помогают команде работать в одном стиле.',1,2),(19,5,'Стандарты нужны только для формальных проверок и не касаются реальной работы.',0,3),(20,5,'Стандарты ограничивают коммуникацию с гостем и запрещают инициативу.',0,4),(21,6,'Гость просто не хочет покупать и ищет повод уйти.',0,1),(22,6,'Гостю всегда не хватает денег.',0,2),(23,6,'Гость пока не видит достаточной ценности продукта по сравнению с ценой.',1,3),(24,6,'Гостю не нравится сотрудник.',0,4),(25,7,'«В этом тарифе 10 занятий и 5 вебинаров.»',0,1),(26,7,'«Эта услуга стоит дешевле, чем у конкурентов.»',0,2),(27,7,'«Участие в программе за 2 недели поможет вам уверенно общаться с гостями и чувствовать себя спокойнее в сложных ситуациях.»',1,3),(28,7,'«У нас современное оборудование и удобный сайт.»',0,4),(29,8,'Спокойно выслушать возражение.',0,1),(30,8,'Уточнить, что именно беспокоит гостя.',0,2),(31,8,'Согласиться в части и дать аргумент.',0,3),(32,8,'Игнорировать возражение и продолжать презентацию, чтобы не развивать тему.',1,4),(33,9,'Приветствие гостя при входе.',0,1),(34,9,'Демонстрация продукта.',0,2),(35,9,'Благодарность за покупку, уточнение дальнейших шагов и предложение обратиться при вопросах.',1,3),(36,9,'Работа с возражением «дорого».',0,4),(37,10,'Настойчиво несколько раз предложить оформить покупку, не обращая внимания на реакцию гостя.',0,1),(38,10,'Сделать вид, что этап оформления не важен, и ждать, пока гость сам предложит оплатить.',0,2),(39,10,'Мягко предложить оформить решение, опираясь на ранее озвученные потребности и выгоды.',1,3),(40,10,'Задать гостю много технических вопросов, чтобы он устал и согласился быстрее.',0,4),(41,11,'Создавать ценность для гостей через качественный сервис и продукт',1,1),(42,11,'Максимизировать прибыль любой ценой',0,2),(43,11,'Сократить издержки за счёт сокращения персонала',0,3),(44,11,'Избегать изменений и сохранять статус-кво',0,4),(45,12,'Вежливость, отзывчивость и ориентация на решение проблемы гостя',1,1),(46,12,'Строгое следование скрипту независимо от ситуации',0,2),(47,12,'Обсуждение личных проблем с гостями',0,3),(48,12,'Игнорирование гостя, если он не жалуется',0,4),(49,13,'Признать, что не знает, и уточнить информацию у коллег/руководителя',1,1),(50,13,'Сделать вид, что не слышит вопрос',0,2),(51,13,'Придумать ответ, чтобы не выглядеть неопытным',0,3),(52,13,'Сказать гостю, что это «не моя зона ответственности»',0,4),(53,14,'С приветствия, визуального контакта и доброжелательного настроя',1,1),(54,14,'С обсуждения проблем в коллективе при госте',0,2),(55,14,'С проверки телефона и личных сообщений',0,3),(56,14,'С ожидания, пока гость сам обратится и подождёт',0,4),(57,15,'Выслушать, проявить эмпатию и предложить решение в рамках стандартов',1,1),(58,15,'Обвинить гостя в том, что он «слишком придирчивый»',0,2),(59,15,'Игнорировать жалобу, если гость говорит спокойно',0,3),(60,15,'Перевести внимание на другого гостя',0,4),(61,16,'Поблагодарить гостя и попрощаться вежливо, пригласив вернуться снова',1,1),(62,16,'Просто развернуться и уйти после расчёта',0,2),(63,16,'Задержать гостя, чтобы обсудить рабочие вопросы',0,3),(64,16,'Ничего не говорить, чтобы «не мешать»',0,4),(65,17,'Потребности гостя и задачу, которую продукт должен решать',1,1),(66,17,'Личный вкус сотрудника',0,2),(67,17,'Самый дорогой вариант из ассортимента',0,3),(68,17,'Тот продукт, который нужно «распродать быстрее»',0,4),(69,18,'Связать характеристики продукта с выгодами для гостя на понятном языке',1,1),(70,18,'Перечислить все технические параметры подряд без примеров',0,2),(71,18,'Сказать, что «все так берут, даже не думайте»',0,3),(72,18,'Ответить: «не знаю, но продукт хороший»',0,4),(73,19,'Предложение дополнительного продукта, логично дополняющего основной',1,1),(74,19,'Навязывание лишних товаров без связи с потребностью гостя',0,2),(75,19,'Продажа максимально дорогого товара независимо от запроса',0,3),(76,19,'Игнорирование возможности предложить что-то ещё',0,4);
/*!40000 ALTER TABLE `test_answers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `test_attempt_answers`
--

DROP TABLE IF EXISTS `test_attempt_answers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `test_attempt_answers` (
  `id` int NOT NULL AUTO_INCREMENT,
  `attempt_id` int NOT NULL,
  `question_id` int NOT NULL,
  `answer_id` int DEFAULT NULL COMMENT 'Если выбрали вариант',
  `answer_text_manual` text COLLATE utf8mb4_unicode_ci COMMENT 'Если текстовый ответ',
  `is_correct` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_attempt_answers_attempt` (`attempt_id`),
  KEY `fk_attempt_answers_question` (`question_id`),
  KEY `fk_attempt_answers_answer` (`answer_id`),
  CONSTRAINT `fk_attempt_answers_answer` FOREIGN KEY (`answer_id`) REFERENCES `test_answers` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_attempt_answers_attempt` FOREIGN KEY (`attempt_id`) REFERENCES `test_attempts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_attempt_answers_question` FOREIGN KEY (`question_id`) REFERENCES `test_questions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Ответы пользователя в конкретной попытке теста';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `test_attempt_answers`
--

LOCK TABLES `test_attempt_answers` WRITE;
/*!40000 ALTER TABLE `test_attempt_answers` DISABLE KEYS */;
/*!40000 ALTER TABLE `test_attempt_answers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `test_attempts`
--

DROP TABLE IF EXISTS `test_attempts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `test_attempts` (
  `id` int NOT NULL AUTO_INCREMENT,
  `test_id` int NOT NULL,
  `user_id` int NOT NULL,
  `enrollment_id` int DEFAULT NULL COMMENT 'Если тест привязан к конкретному назначению курса',
  `started_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `finished_at` datetime DEFAULT NULL,
  `score_raw` decimal(6,2) DEFAULT NULL COMMENT 'Набранные баллы',
  `score_percent` decimal(5,2) DEFAULT NULL COMMENT 'Процент, 0–100',
  `is_passed` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_attempts_test` (`test_id`),
  KEY `fk_attempts_user` (`user_id`),
  KEY `fk_attempts_enrollment` (`enrollment_id`),
  CONSTRAINT `fk_attempts_enrollment` FOREIGN KEY (`enrollment_id`) REFERENCES `course_enrollments` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_attempts_test` FOREIGN KEY (`test_id`) REFERENCES `tests` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_attempts_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Попытки прохождения тестов';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `test_attempts`
--

LOCK TABLES `test_attempts` WRITE;
/*!40000 ALTER TABLE `test_attempts` DISABLE KEYS */;
/*!40000 ALTER TABLE `test_attempts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `test_questions`
--

DROP TABLE IF EXISTS `test_questions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `test_questions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `test_id` int NOT NULL,
  `question_text` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `question_type` enum('single_choice','multiple_choice','text') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'single_choice',
  `score` decimal(5,2) NOT NULL DEFAULT '1.00' COMMENT 'Вес вопроса',
  `sort_order` int NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `fk_questions_test` (`test_id`),
  CONSTRAINT `fk_questions_test` FOREIGN KEY (`test_id`) REFERENCES `tests` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Вопросы тестов';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `test_questions`
--

LOCK TABLES `test_questions` WRITE;
/*!40000 ALTER TABLE `test_questions` DISABLE KEYS */;
INSERT INTO `test_questions` VALUES (1,1,'Какова главная цель качественного сервиса для компании?','single_choice',1.00,1),(2,1,'Какой из вариантов наиболее точно отражает правильный порядок этапов продаж?','single_choice',1.00,2),(3,1,'Какой вопрос является открытым?','single_choice',1.00,3),(4,1,'Что означает этап «выявление потребностей»?','single_choice',1.00,4),(5,1,'Какое утверждение о стандартах обслуживания верное?','single_choice',1.00,5),(6,1,'Что обычно скрывается за возражением «Дорого»?','single_choice',1.00,6),(7,1,'Какой из вариантов отражает презентацию через выгоды, а не через характеристики?','single_choice',1.00,7),(8,1,'Какой шаг НЕ входит в базовый алгоритм работы с возражениями?','single_choice',1.00,8),(9,1,'Что относится к постсервису?','single_choice',1.00,9),(10,1,'Как лучше всего корректно завершить продажу?','single_choice',1.00,10),(11,2,'Как кратко можно описать миссию нашей компании?','single_choice',1.00,1),(12,2,'Что из перечисленного является ключевым принципом работы с гостями?','single_choice',1.00,2),(13,2,'Как сотруднику следует поступить, если он не знает ответ на вопрос гостя?','single_choice',1.00,3),(14,3,'С чего начинается качественное обслуживание гостя?','single_choice',1.00,1),(15,3,'Как правильно реагировать на жалобу гостя?','single_choice',1.00,2),(16,3,'Что является правильным завершением контакта с гостем?','single_choice',1.00,3),(17,4,'Что важно в первую очередь учитывать при подборе продукта для гостя?','single_choice',1.00,1),(18,4,'Как лучше презентовать преимущества продукта гостю?','single_choice',1.00,2),(19,4,'Что является корректным кросс-продажей?','single_choice',1.00,3);
/*!40000 ALTER TABLE `test_questions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tests`
--

DROP TABLE IF EXISTS `tests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tests` (
  `id` int NOT NULL AUTO_INCREMENT,
  `course_id` int NOT NULL,
  `module_id` int DEFAULT NULL COMMENT 'Опционально: тест по модулю',
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `passing_score` int NOT NULL DEFAULT '70' COMMENT 'Порог прохождения, %',
  `attempts_limit` int DEFAULT NULL COMMENT 'Максимум попыток (NULL - без ограничения)',
  `sort_order` int NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `is_final` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `fk_tests_course` (`course_id`),
  KEY `fk_tests_module` (`module_id`),
  CONSTRAINT `fk_tests_course` FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_tests_module` FOREIGN KEY (`module_id`) REFERENCES `course_modules` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Тесты по курсам';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tests`
--

LOCK TABLES `tests` WRITE;
/*!40000 ALTER TABLE `tests` DISABLE KEYS */;
INSERT INTO `tests` VALUES (1,1,NULL,'Итоговый тест по техникам продаж и обслуживанию гостей','Проверка ключевых знаний по этапам продаж, сервису и работе с возражениями.',70,3,1,1,1),(2,1,1,'Вводный тест по компании','Проверьте базовые знания о компании, её миссии и ключевых правилах.',70,NULL,1,1,0),(3,1,2,'Тест по стандартам обслуживания гостей','Проверка понимания основных стандартов сервиса и этапов обслуживания гостя.',80,NULL,1,1,0),(4,1,3,'Тест по линейке продуктов и услуг','Проверьте знание ассортимента, ключевых характеристик и выгод для гостя.',75,NULL,1,1,0);
/*!40000 ALTER TABLE `tests` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `role_id` int NOT NULL,
  `email` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `first_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `last_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `patronymic` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_login_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`),
  KEY `fk_users_role` (`role_id`),
  CONSTRAINT `fk_users_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Пользователи системы';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,1,'admin@company.local','admin_hash','Иван','Админов','Петрович',1,'2025-12-02 23:04:32','2025-12-03 13:04:37'),(2,2,'trainer@company.local','trainer_hash','Мария','Тренерова','Сергеевна',1,'2025-12-02 23:04:32',NULL),(3,3,'emp1@company.local','emp1_hash','Алексей','Новиков','Игоревич',1,'2025-12-02 23:04:32','2025-12-03 00:48:22'),(4,3,'emp2@company.local','emp2_hash','Ольга','Смирнова','Андреевна',1,'2025-12-02 23:04:32',NULL);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'onboarding_training'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-12-03 16:25:23

