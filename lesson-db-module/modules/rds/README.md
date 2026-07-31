# Модуль `rds` — Amazon RDS або Aurora

Перемикач — `use_aurora`:

| `use_aurora` | Ресурси |
|---|---|
| `false` | `aws_db_instance` + `aws_db_parameter_group` (+ read-репліки) |
| `true` | `aws_rds_cluster` + `aws_rds_cluster_instance` × N (writer + readers) + `aws_rds_cluster_parameter_group` |
| обидва | `aws_db_subnet_group`, `aws_security_group` + правила, `random_password` (якщо пароль не передали) |

Виводи однакові в обох режимах, тому решта коду не помічає різниці.

```
shared.tf     # locals, subnet group, security group, parameter groups, пароль
rds.tf        # aws_db_instance (+ read-репліки)        use_aurora = false
aurora.tf     # aws_rds_cluster + writer + readers      use_aurora = true
variables.tf  # 34 змінні з типами, описами, дефолтами, валідацією
outputs.tf    # 17 виводів
```

## Приклад: звичайна RDS PostgreSQL

```hcl
module "rds" {
  source = "./modules/rds"

  name       = "myapp-db"
  use_aurora = false

  engine                     = "postgres"
  engine_version             = "16"
  parameter_group_family_rds = "postgres16"

  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = "myapp"
  username = "postgres"
  password = var.db_password   # або не передавати — модуль згенерує

  vpc_id              = module.vpc.vpc_id
  subnet_private_ids  = module.vpc.private_subnet_ids
  subnet_public_ids   = module.vpc.public_subnet_ids
  publicly_accessible = false

  allowed_cidr_blocks        = [module.vpc.vpc_cidr_block]
  allowed_security_group_ids = [aws_security_group.app.id]

  multi_az                = false
  backup_retention_period = 7

  parameters = {
    max_connections = "100"
    log_statement   = "all"
    work_mem        = "4096"
  }

  tags = { Environment = "dev", Project = "myapp" }
}
```

## Приклад: Aurora PostgreSQL

Той самий блок, змінені чотири рядки:

```hcl
  use_aurora = true

  engine_cluster                = "aurora-postgresql"
  engine_version_cluster        = "16"
  parameter_group_family_aurora = "aurora-postgresql16"
  aurora_instance_count         = 2       # 1 writer + 1 reader

  instance_class = "db.t4g.medium"        # Aurora не підтримує db.t3.micro
```

`allocated_storage` не потрібен: Aurora нарощує сховище автоматично.

## Як що змінити

| Задача | Що зробити |
|---|---|
| **RDS ⇄ Aurora** | `use_aurora = true/false`. Aurora-змінні (`*_cluster`, `parameter_group_family_aurora`) читаються лише в режимі Aurora, RDS-змінні (`engine`, `engine_version`, `parameter_group_family_rds`, `allocated_storage`) — лише у звичайному, тож обидва набори можуть лежати в одному блоці. Це заміна ресурсу: стара база знищується, нова створюється. |
| **Тип БД на MySQL** | `engine = "mysql"`, `engine_version = "8.0"` (або `engine_cluster = "aurora-mysql"`). Порт 3306 модуль підставить сам. **Обов'язково перевизначте `parameters`**: `log_statement` і `work_mem` існують лише в PostgreSQL. Напр. `{ max_connections = "200", slow_query_log = "1", long_query_time = "2" }`. |
| **Версія** | `engine_version` / `engine_version_cluster`. `"16"` — AWS бере найсвіжіший мінор, `"16.4"` — фіксує точну. Родину parameter group модуль виведе сам. |
| **Клас інстансу** | `instance_class`. Для Aurora — не нижче `db.t4g.medium`; застосовується до кожного члена кластера. |
| **Розмір диска** | `allocated_storage` + `max_allocated_storage` для автомасштабування (`0` — вимкнено). Для Aurora не застосовується. |
| **Читачі** | Aurora: `aurora_instance_count = 3` (1 writer + 2 readers) або явно `aurora_replica_count`. RDS: `read_replica_count = 1` (потребує `backup_retention_period > 0`). |
| **Відмовостійкість** | RDS: `multi_az = true` — standby в іншій AZ, трафік не обслуговує. Aurora: сховище вже на трьох AZ, тому `multi_az = true` вимагає щонайменше одного читача. |
| **Доступ ззовні** | `publicly_accessible = true` — модуль переносить базу з `subnet_private_ids` у `subnet_public_ids`; плюс `allowed_cidr_blocks = ["203.0.113.10/32"]`. |
| **Доступ застосунку** | `allowed_security_group_ids = [<sg клієнта>]` — надійніше за CIDR. |
| **Параметри БД** | `parameters` — довільна мапа. Статичні (`max_connections`) застосовуються після рестарту, тому дефолтний `apply_method` — `pending-reboot`; для динамічних (`work_mem`, `log_statement`) модуль ставить `immediate`. |

## Змінні

### Ідентифікація та режим

| Змінна | Тип | Дефолт | Опис |
|---|---|---|---|
| `name` | `string` | обов'язкова | Ім'я інстансу або `<name>-cluster`; префікс для subnet group, SG, parameter group. |
| `use_aurora` | `bool` | `false` | Aurora-кластер чи одиночний RDS-інстанс. |

### Engine

| Змінна | Тип | Дефолт | Опис |
|---|---|---|---|
| `engine` | `string` | `postgres` | Движок звичайної RDS: `postgres`, `mysql`, `mariadb`. Валідація забороняє тут Aurora-движки. |
| `engine_version` | `string` | `16` | Версія звичайної RDS. |
| `engine_cluster` | `string` | `aurora-postgresql` | Движок Aurora: `aurora-postgresql` або `aurora-mysql`. |
| `engine_version_cluster` | `string` | `16` | Версія Aurora. Підтримувані версії відстають від upstream. |

### Розмір

| Змінна | Тип | Дефолт | Опис |
|---|---|---|---|
| `instance_class` | `string` | `db.t3.micro` | Клас інстансу або кожного члена кластера. |
| `allocated_storage` | `number` | `20` | Диск у ГіБ. Лише для звичайної RDS. |
| `max_allocated_storage` | `number` | `0` | Межа автомасштабування диска; `0` — вимкнено. |
| `storage_type` | `string` | `gp3` | `gp2`, `gp3`, `io1`, `io2`. Free tier — `gp2`. |
| `aurora_instance_count` | `number` | `2` | Загальна кількість членів кластера: перший — writer, решта — readers. |
| `aurora_replica_count` | `number` | `null` | Явна кількість readers; перекриває `aurora_instance_count - 1`. |
| `read_replica_count` | `number` | `0` | Read-репліки звичайної RDS. Потребує `backup_retention_period > 0`. |

### Креденшели

| Змінна | Тип | Дефолт | Опис |
|---|---|---|---|
| `db_name` | `string` | `appdb` | Ім'я початкової бази. |
| `username` | `string` | `dbadmin` | Майстер-користувач. |
| `password` | `string` (sensitive) | `null` | Пароль, мін. 8 символів. `null` → `random_password` без символів, які RDS відхиляє. |

### Мережа

| Змінна | Тип | Дефолт | Опис |
|---|---|---|---|
| `vpc_id` | `string` | обов'язкова | VPC для security group. |
| `subnet_private_ids` | `list(string)` | `[]` | Приватні сабнети — при `publicly_accessible = false`. |
| `subnet_public_ids` | `list(string)` | `[]` | Публічні сабнети — при `publicly_accessible = true`. |
| `publicly_accessible` | `bool` | `false` | Публічна адреса + вибір набору сабнетів. |
| `port` | `number` | `null` | `null` → 5432 для PostgreSQL, 3306 для MySQL/MariaDB. |
| `allowed_cidr_blocks` | `list(string)` | `[]` | CIDR-и з доступом до порту. Порожньо = жодного правила; `0.0.0.0/0` модуль сам не відкриває. |
| `allowed_security_group_ids` | `list(string)` | `[]` | Security groups клієнтів з доступом до порту. |

Subnet group вимагає щонайменше два сабнети у двох AZ — інакше `precondition`
зупиняє `plan`, а не AWS через п'ять хвилин.

### Parameter group

| Змінна | Тип | Дефолт | Опис |
|---|---|---|---|
| `parameter_group_family_rds` | `string` | `null` | Родина для RDS. `null` → `<engine><major>`, напр. `postgres16`. |
| `parameter_group_family_aurora` | `string` | `null` | Родина для Aurora. `null` → `aurora-postgresql16`. |
| `parameters` | `map(string)` | `max_connections=100`, `log_statement=all`, `work_mem=4096` | Параметри БД: у DB parameter group (RDS) або DB cluster parameter group (Aurora). |
| `parameters_apply_method` | `map(string)` | `log_statement=immediate`, `work_mem=immediate` | Спосіб застосування окремих параметрів. |
| `default_apply_method` | `string` | `pending-reboot` | Спосіб застосування для решти. |

Обидві групи створюються через `name_prefix` + `create_before_destroy`: зміна
версії движка замінює групу, і без цього Terraform упирався б у конфлікт імен.

### Доступність, бекапи, захист

| Змінна | Тип | Дефолт | Опис |
|---|---|---|---|
| `multi_az` | `bool` | `false` | RDS: standby в іншій AZ. Aurora: вимагає ≥1 читача. |
| `backup_retention_period` | `number` | `7` | Днів зберігання автобекапів, 0–35. На free tier максимум `1`. |
| `preferred_backup_window` | `string` | `03:00-04:00` | Вікно бекапів (UTC). |
| `preferred_maintenance_window` | `string` | `sun:04:30-sun:05:30` | Вікно обслуговування (UTC). |
| `auto_minor_version_upgrade` | `bool` | `true` | Автооновлення мінорних версій. |
| `apply_immediately` | `bool` | `false` | Застосовувати зміни одразу, не чекаючи вікна обслуговування. |
| `storage_encrypted` | `bool` | `true` | Шифрування at rest. |
| `kms_key_id` | `string` | `null` | Свій KMS-ключ; `null` — `aws/rds`. |
| `deletion_protection` | `bool` | `false` | Заборона видалення БД. |
| `skip_final_snapshot` | `bool` | `true` | `false` створює снапшот `<name>-final-snapshot` перед видаленням. |
| `performance_insights_enabled` | `bool` | `false` | Performance Insights (не працює на `db.t3.micro`). |
| `tags` | `map(string)` | `{}` | Теги на всі ресурси; модуль додає `ManagedBy` і `Name`. |

## Виводи

| Вивід | Опис |
|---|---|
| `is_aurora` | Який режим розгорнуто. |
| `identifier`, `arn` | Ідентифікатор і ARN кластера або інстансу. |
| `endpoint` | Хост для запису: writer endpoint Aurora або адреса RDS-інстансу. |
| `reader_endpoint` | Хост для читання: reader endpoint Aurora або перша read-репліка; `null`, якщо читачів немає. |
| `replica_endpoints` | Адреси всіх читачів. |
| `port`, `db_name`, `username` | Параметри підключення. |
| `password` | Пароль (sensitive). |
| `connection_url` | Готовий URL `postgresql://…` / `mysql://…` (sensitive). |
| `engine`, `engine_version` | Фактично розгорнутий движок і версія. |
| `security_group_id`, `db_subnet_group_name`, `parameter_group_name`, `parameter_group_family` | Спільні ресурси. |
