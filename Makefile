CWD := $(shell docker compose run php pwd)
TOOLS_DIR := "$(CWD)/tools"
COMPOSE_RUN := docker compose run --rm
COMPOSE_PHP := $(COMPOSE_RUN) php
COMPOSE_COMPOSER := $(COMPOSE_RUN) composer
COMPOSE_SYMFONY := $(COMPOSE_RUN) symfony
COMPOSE_NPM := $(COMPOSE_RUN) npm

# *******************************
# Application related
# *******************************

# Run symfony console
.PHONY: symfony
symfony:
	$(COMPOSE_SYMFONY)

# Run composer console
.PHONY: composer
composer:
	$(COMPOSE_COMPOSER)

# Create a new migration
.PHONY: mig.c
mig.c:
	$(COMPOSE_SYMFONY) console make:migration

# Migrate to database
.PHONY: mig.m
mig.m:
	$(COMPOSE_SYMFONY) console doctrine:migrations:migrate --no-interaction

# Recreate database
.PHONY: db.flush
db.flush:
	$(COMPOSE_SYMFONY) console doctrine:database:drop --force
	$(COMPOSE_SYMFONY) console doctrine:database:create

# Recreate a fresh database
.PHONY: db.fresh
db.fresh:
	make db.flush
	make app.mig.m

# Load fixtures (add `--group=<name>` to launch specific fixtures)
.PHONY: db.fake
db.fake:
	$(COMPOSE_SYMFONY) console doctrine:fixtures:load

# Make a migration and migrate automatically
.PHONY: migration
migration:
	make mig.c
	make mig.m

# Completely recreate database (env=dev)
.PHONY: seed.dev
seed.dev:
	make db.fresh
	$(COMPOSE_SYMFONY) console doctrine:fixtures:load --group=dev

# Completely recreate database (env=prod)
.PHONY: seed.prod
seed.prod:
	make db.fresh
	$(COMPOSE_SYMFONY) console doctrine:fixtures:load --group=prod

# Clear caches
.PHONY: cc.dev
cc.dev:
	$(COMPOSE_SYMFONY) console cache:clear --env=dev

.PHONY: cc.prod
cc.prod:
	$(COMPOSE_SYMFONY) console cache:clear --env=prod

.PHONY: cc.test
cc.test:
	$(COMPOSE_SYMFONY) console cache:clear --env=test

.PHONY: cc
cc:
	make cc.dev
	make cc.prod
	make cc.test

# *******************************
# Tools related
# *******************************

# Install php dependencies
.PHONY: install.php
install.php:
	$(COMPOSE_COMPOSER) install
	$(COMPOSE_COMPOSER) install --working-dir=$(TOOLS_DIR)/phpmd
	$(COMPOSE_COMPOSER) install --working-dir=$(TOOLS_DIR)/phpcs
	$(COMPOSE_COMPOSER) install --working-dir=$(TOOLS_DIR)/phpcsfixer
	$(COMPOSE_COMPOSER) install --working-dir=$(TOOLS_DIR)/phpstan
	$(COMPOSE_COMPOSER) install --working-dir=$(TOOLS_DIR)/phpcpd

# Install node dependencies
.PHONY: install.npm
install.npm:
	$(COMPOSE_NPM) install

# Install all dependencies
.PHONY: install
install:
	make install.php
	make install.npm

# Launch PHP CS Fixer (see https://github.com/PHP-CS-Fixer/PHP-CS-Fixer)
.PHONY: fix
fix:
	$(COMPOSE_PHP) $(TOOLS_DIR)/php-cs-fixer/vendor/bin/php-cs-fixer fix

# Launch PHPStan (see https://phpstan.org/)
.PHONY: stan
stan:
	$(COMPOSE_PHP) $(TOOLS_DIR)/phpstan/vendor/bin/phpstan analyse -c phpstan.neon src

# Launch PHPStan with a file pattern (see https://phpstan.org/)
# Append the path to a file or directory to launch the analysis only on it
.PHONY: stan.f
stan.f:
	$(COMPOSE_PHP) $(TOOLS_DIR)/phpstan/vendor/bin/phpstan analyse -c phpstan.neon

# Launch PHP Mess Detector (see https://phpmd.org/)
.PHONY: phpmd
phpmd:
	$(COMPOSE_PHP) $(TOOLS_DIR)/phpmd/vendor/bin/phpmd src/ text .phpmd.xml

# Launch PHP_CodeSniffer (see https://github.com/squizlabs/PHP_CodeSniffer)
.PHONY: phpcs
phpcs:
	$(COMPOSE_PHP) $(TOOLS_DIR)/phpcs/vendor/bin/phpcs -s --standard=phpcs.xml.dist

# Launch PHP_CodeBeautifier (see https://github.com/squizlabs/PHP_CodeSniffer)
.PHONY: phpcbf
phpcbf:
	$(COMPOSE_PHP) $(TOOLS_DIR)/phpcs/vendor/bin/phpcbf --standard=phpcs.xml.dist ./src ./tests

# Launch PHP Copy/Paste Detector (see https://github.com/sebastianbergmann/phpcpd)
.PHONY: phpcpd
phpcpd:
	$(COMPOSE_PHP) $(TOOLS_DIR)/phpcpd/vendor/bin/phpcpd src/

# Launch all linting tools for backend code
.PHONY: lint.php
lint.php:
	make phpmd
	make phpcpd
	make phpcs
	make phpstan
	make fix
	make phpcbf

# Launch ES Lint in the project
.PHONY: eslint
eslint:
	$(COMPOSE_NPM) run eslint

# Launch Prettier in the project
.PHONY: prettier
prettier:
	$(COMPOSE_NPM) run prettier

# Launch ES Lint in the project (in watch mode)
.PHONY: eslint.w
eslint.w:
	$(COMPOSE_NPM) run eslint:watch

# Launch Prettier in the project (in watch mode)
.PHONY: prettier.w
prettier.w:
	$(COMPOSE_NPM) run prettier:watch


# *******************************
# Environment related
# *******************************

# Deploy to production server.
# Append the ssh destination at the end, eg. my_ssh_server:/my/directory
.PHONY: mep
mep:
	rsync -avz --exclude-from=".rsyncignore.txt" --delete ./


# *******************************
# Boilerplate related
# *******************************

.PHONY: i.phpmd
i.phpmd:
	$(COMPOSE_PHP) mkdir -p $(TOOLS_DIR)/phpmd
	$(COMPOSE_COMPOSER) require --dev phpmd/phpmd --working-dir $(TOOLS_DIR)/phpmd

.PHONY: i.phpcs
i.phpcs:
	$(COMPOSE_PHP) mkdir -p $(TOOLS_DIR)/phpcs
	$(COMPOSE_COMPOSER) require --dev squizlabs/php_codesniffer escapestudios/symfony2-coding-standard --working-dir $(TOOLS_DIR)/phpcs

.PHONY: i.phpcsfixer
i.phpcsfixer:
	$(COMPOSE_PHP) mkdir -p $(TOOLS_DIR)/phpcsfixer
	$(COMPOSE_COMPOSER) require --dev friendsofphp/php-cs-fixer --working-dir $(TOOLS_DIR)/phpcsfixer

.PHONY: i.phpstan
i.phpstan:
	$(COMPOSE_PHP) mkdir -p $(TOOLS_DIR)/phpstan
	$(COMPOSE_COMPOSER) require --dev phpstan/phpstan phpstan/phpstan-symfony phpstan/phpstan-doctrine --working-dir $(TOOLS_DIR)/phpstan

.PHONY: i.phpcpd
i.phpcpd:
	$(COMPOSE_PHP) mkdir -p $(TOOLS_DIR)/phpcpd
	$(COMPOSE_COMPOSER) require --dev sebastian/phpcpd --working-dir $(TOOLS_DIR)/phpcpd

.PHONY: i.tools
i.tools:
	$(COMPOSE_PHP) mkdir -p $(TOOLS_DIR)
	$(COMPOSE_PHP) echo -e "\n###> php-tooling ###\n.DS_Store\n.php-cs-fixer.cache\n.phpcs.cache\n.idea/\n.vscode/\nvendor/\nnode_modules/\n###< php-tooling ###" >> .gitignore
	make i.phpmd
	make i.phpcs
	make i.phpcsfixer
	make i.phpstan
	make i.phpcpd

.PHONY: i.symfony
i.symfony:
	$(COMPOSE_SYMFONY) new temporary_dir
	$(COMPOSE_PHP) rm -rf temporary_dir/.git && cp -R temporary_dir/. . && rm -rf temporary_dir
	make i.tools
	$(COMPOSE_COMPOSER) install
