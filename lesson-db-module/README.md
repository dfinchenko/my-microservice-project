# Тема 10 — універсальний Terraform-модуль `rds`: Amazon RDS або Aurora

Модуль, який залежно від `use_aurora` піднімає **або** звичайний RDS-інстанс,
**або** Aurora-кластер із writer-ом і читачами. DB subnet group, security group і
parameter group створюються в обох випадках, виводи однакові.

| `use_aurora` | Ресурси |
|---|---|
| `false` | `aws_db_instance` + `aws_db_parameter_group` (+ read-репліки) |
| `true` | `aws_rds_cluster` + `aws_rds_cluster_instance` × N (writer + readers) + `aws_rds_cluster_parameter_group` |
| обидва | `aws_db_subnet_group`, `aws_security_group` + правила, `random_password` (якщо пароль не передали) |

Опис усіх змінних і виводів модуля: [`modules/rds/README.md`](modules/rds/README.md).

## Структура

```
lesson-db-module/
├── main.tf backend.tf providers.tf variables.tf outputs.tf
└── modules/
    ├── s3-backend/    # S3 + DynamoDB для стейту
    ├── vpc/           # VPC, публічні й приватні підмережі, IGW, маршрути
    └── rds/           # ✅ модуль теми
        ├── shared.tf rds.tf aurora.tf variables.tf outputs.tf
        └── README.md
```

У VPC немає NAT Gateway: база в приватних підмережах не потребує вихідного
інтернету, а NAT коштував би дорожче за всю решту конфігурації разом.

## Приклад використання

`main.tf` — обидва набори змінних лежать в одному блоці, бо модуль читає лише ті,
що відповідають поточному режиму:

```hcl
module "rds" {
  source = "./modules/rds"

  name       = var.db_identifier
  use_aurora = var.use_aurora          # ← єдиний перемикач

  # --- Aurora-only (use_aurora = true) ---
  engine_cluster                = "aurora-postgresql"
  engine_version_cluster        = "16"
  parameter_group_family_aurora = "aurora-postgresql16"
  aurora_instance_count         = 2

  # --- RDS-only (use_aurora = false) ---
  engine                     = "postgres"
  engine_version             = "16"
  parameter_group_family_rds = "postgres16"
  allocated_storage          = 20
  storage_type               = "gp2"

  # --- Спільні ---
  instance_class = var.db_instance_class
  db_name        = var.db_name
  username       = var.db_username
  password       = var.db_password

  vpc_id              = module.vpc.vpc_id
  subnet_private_ids  = module.vpc.private_subnet_ids
  subnet_public_ids   = module.vpc.public_subnet_ids
  publicly_accessible = var.db_publicly_accessible

  allowed_cidr_blocks = concat([module.vpc.vpc_cidr_block], var.db_allowed_cidr_blocks)

  multi_az                = var.use_aurora
  backup_retention_period = var.db_backup_retention_period
  storage_encrypted       = true
  skip_final_snapshot     = true

  parameters = {
    max_connections = "100"
    log_statement   = "all"
    work_mem        = "4096"
  }

  tags = { Environment = "dev", Project = "lesson-db-module" }
}
```

Модуль сам виводить порт із движка (5432 / 3306), родину parameter group із
движка й версії (`postgres16`), набір сабнетів із `publicly_accessible` і пароль,
якщо його не передали.

## Змінні кореневого конфіга

| Змінна | Тип | Дефолт | Опис |
|---|---|---|---|
| `aws_region` | `string` | `us-east-1` | Регіон. |
| `use_aurora` | `bool` | `false` | Перемикач RDS ⇄ Aurora. |
| `db_identifier` | `string` | `lesson-db-module-db` | Ім'я інстансу / кластера. |
| `db_instance_class` | `string` | `db.t3.micro` | Клас інстансу. Для Aurora — від `db.t4g.medium`. |
| `db_name` | `string` | `appdb` | Ім'я початкової бази. |
| `db_username` | `string` | `dbadmin` | Майстер-користувач. |
| `db_password` | `string` (sensitive) | `null` | Пароль; `null` — Terraform згенерує. |
| `db_backup_retention_period` | `number` | `1` | Днів зберігання бекапів. На free tier максимум 1. |
| `db_publicly_accessible` | `bool` | `false` | Публічна адреса + публічні сабнети. |
| `db_allowed_cidr_blocks` | `list(string)` | `[]` | Додаткові CIDR понад саму VPC. |

## Запуск

Потрібні AWS CLI з креденшелами, Terraform ≥ 1.5 і `psql` для перевірки.

Bootstrap бекенду (один раз):

```bash
cd lesson-db-module
terraform init
terraform apply -target=module.s3_backend
# розкоментувати блок backend "s3" у backend.tf
terraform init -migrate-state
```

Звичайна RDS PostgreSQL — дефолт, ~10 хвилин:

```bash
terraform apply
```

Aurora — та сама команда з іншим значенням прапорця, ~15 хвилин:

```bash
terraform apply -var="use_aurora=true" -var="db_instance_class=db.t4g.medium"
```

Aurora не підтримує `db.t3.micro`, тому клас задається разом із прапорцем.
Перемикання **замінює** базу: Terraform знищує інстанс і створює кластер.

Як змінити движок на MySQL, версію, розмір диска чи параметри БД — таблиця
«Як що змінити» в [`modules/rds/README.md`](modules/rds/README.md).

## Перевірка

```bash
terraform output
terraform output -raw db_password
```

```bash
aws rds describe-db-subnet-groups --db-subnet-group-name lesson-db-module-db-subnet-group \
  --query 'DBSubnetGroups[0].Subnets[].SubnetAvailabilityZone.Name'      # три різні AZ

aws rds describe-db-parameters \
  --db-parameter-group-name "$(terraform output -raw db_parameter_group_name)" \
  --source user --query 'Parameters[].[ParameterName,ParameterValue,ApplyMethod]' --output table

aws ec2 describe-security-groups --group-ids "$(terraform output -raw db_security_group_id)" \
  --query 'SecurityGroups[0].IpPermissions'                             # лише 5432 з CIDR VPC
```

База стоїть у приватних підмережах і слухає лише VPC, тож для перевірки
підключення з ноутбука її треба тимчасово відкрити:

```bash
MY_IP=$(curl -s https://checkip.amazonaws.com)/32
terraform apply -var="db_publicly_accessible=true" -var="db_allowed_cidr_blocks=[\"$MY_IP\"]"

psql "$(terraform output -raw db_connection_url)" \
  -c 'show max_connections; show work_mem; show log_statement;'

terraform apply    # повернути базу в приватну мережу
```

Значення мають збігатися з `parameters` у `main.tf`. `max_connections` —
статичний параметр, застосовується після рестарту БД, `work_mem` і
`log_statement` — динамічні, застосовуються одразу.

## Видалення

```bash
terraform destroy
```

У `main.tf` задано `skip_final_snapshot = true` і `deletion_protection = false`,
тому `destroy` проходить одразу й без фінального снапшота. Якщо дані потрібно
зберегти, задайте в блоці `module "rds"`:

```hcl
skip_final_snapshot = false   # перед видаленням створиться lesson-db-module-db-final-snapshot
deletion_protection = true    # destroy впаде з помилкою, поки прапорець не знято
```
