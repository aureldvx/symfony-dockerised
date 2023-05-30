COMPOSE_RUN := "docker compose run --rm"
CWD := `docker compose run --rm php pwd`
TOOLS_DIR := CWD + "/tools"
COMPOSE_PHP := COMPOSE_RUN + " php"
COMPOSE_COMPOSER := COMPOSE_RUN + " composer"
COMPOSE_SYMFONY := COMPOSE_RUN + " symfony"
COMPOSE_NPM := COMPOSE_RUN + " npm"

GITIGNORE_TEMPLATE := '''
###> php-tooling ###
.DS_Store
.php-cs-fixer.cache
.phpcs.cache
.idea/
.vscode/
vendor/
node_modules/
###< php-tooling ###
'''

# *******************************
# Application related
# *******************************

# Create a new migration
mig-c *arguments:
	{{COMPOSE_SYMFONY}} console make:migration {{arguments}}

# Migrate to database
mig-m:
	{{COMPOSE_SYMFONY}} console doctrine:migrations:migrate --no-interaction

# Recreate database
db-flush:
	{{COMPOSE_SYMFONY}} console doctrine:database:drop --force
	{{COMPOSE_SYMFONY}} console doctrine:database:create

# Recreate a fresh database
db-fresh: db-flush mig-m

# Load fixtures (add `--group=<name>` to launch specific fixtures)
seed *arguments:
	{{COMPOSE_SYMFONY}} console doctrine:fixtures:load {{arguments}}

# Make a migration and migrate automatically
migration: mig-c mig-m

# Clear caches
cc env='dev':
	{{COMPOSE_SYMFONY}} console cache:clear --env={{env}}


# *******************************
# Tools related
# *******************************

# Install php dependencies
install-php:
	{{COMPOSE_COMPOSER}} install
	{{COMPOSE_COMPOSER}} install --working-dir={{TOOLS_DIR}}/phpmd
	{{COMPOSE_COMPOSER}} install --working-dir={{TOOLS_DIR}}/phpcs
	{{COMPOSE_COMPOSER}} install --working-dir={{TOOLS_DIR}}/phpcsfixer
	{{COMPOSE_COMPOSER}} install --working-dir={{TOOLS_DIR}}/phpstan
	{{COMPOSE_COMPOSER}} install --working-dir={{TOOLS_DIR}}/phpcpd

# npm alias
npm +arguments:
	{{COMPOSE_NPM}} {{arguments}}

# composer alias
composer +arguments:
	{{COMPOSE_COMPOSER}} {{arguments}}

# symfony console alias
console *arguments:
	{{COMPOSE_SYMFONY}} {{arguments}}

# Install all dependencies
install:
    just composer install
    just npm install

# Launch PHP CS Fixer (see https://github.com/PHP-CS-Fixer/PHP-CS-Fixer)
fixer:
	{{COMPOSE_PHP}} {{TOOLS_DIR}}/php-cs-fixer/vendor/bin/php-cs-fixer fix

# Launch PHPStan (see https://phpstan.org/)
stan *paths='src':
	{{COMPOSE_PHP}} {{TOOLS_DIR}}/phpstan/vendor/bin/phpstan analyse -c phpstan.neon {{paths}}

# Launch PHP Mess Detector (see https://phpmd.org/)
phpmd *paths='src/':
	{{COMPOSE_PHP}} {{TOOLS_DIR}}/phpmd/vendor/bin/phpmd {{paths}} text .phpmd.xml

# Launch PHP_CodeSniffer (see https://github.com/squizlabs/PHP_CodeSniffer)
phpcs:
	{{COMPOSE_PHP}} {{TOOLS_DIR}}/phpcs/vendor/bin/phpcs -s --standard=phpcs.xml.dist

# Launch PHP_CodeBeautifier (see https://github.com/squizlabs/PHP_CodeSniffer)
phpcbf *paths='./src ./tests':
	{{COMPOSE_PHP}} {{TOOLS_DIR}}/phpcs/vendor/bin/phpcbf --standard=phpcs.xml.dist {{paths}}

# Launch PHP Copy/Paste Detector (see https://github.com/sebastianbergmann/phpcpd)
phpcpd *paths='src/':
	{{COMPOSE_PHP}} {{TOOLS_DIR}}/phpcpd/vendor/bin/phpcpd {{paths}}

# Launch all linting tools for backend code
lint-php: phpmd phpcpd phpcs stan fixer phpcbf

# Launch ES Lint in the project
eslint *arguments='src':
	{{COMPOSE_NPM}} ./node_modules/.bin/eslint --fix {{arguments}}

# Launch Prettier in the project
prettier *arguments='src':
	{{COMPOSE_NPM}} ./node_modules/.bin/prettier --write {{arguments}}


# *******************************
# Environment related
# *******************************

# Deploy to production server.
# Append the ssh destination at the end, eg. my_ssh_server:/my/directory
deploy destination:
	rsync -avz --exclude-from=".rsyncignore.txt" --delete ./ {{destination}}


# *******************************
# Boilerplate related
# *******************************

tools-phpmd:
	{{COMPOSE_PHP}} mkdir -p {{TOOLS_DIR}}/phpmd
	{{COMPOSE_COMPOSER}} require --dev phpmd/phpmd --working-dir {{TOOLS_DIR}}/phpmd

tools-phpcs:
	{{COMPOSE_PHP}} mkdir -p {{TOOLS_DIR}}/phpcs
	{{COMPOSE_COMPOSER}} require --dev squizlabs/php_codesniffer escapestudios/symfony2-coding-standard --working-dir {{TOOLS_DIR}}/phpcs

tools-phpcsfixer:
	{{COMPOSE_PHP}} mkdir -p {{TOOLS_DIR}}/phpcsfixer
	{{COMPOSE_COMPOSER}} require --dev friendsofphp/php-cs-fixer --working-dir {{TOOLS_DIR}}/phpcsfixer

tools-phpstan:
	{{COMPOSE_PHP}} mkdir -p {{TOOLS_DIR}}/phpstan
	{{COMPOSE_COMPOSER}} require --dev phpstan/phpstan phpstan/phpstan-symfony phpstan/phpstan-doctrine --working-dir {{TOOLS_DIR}}/phpstan

tools-phpcpd:
	{{COMPOSE_PHP}} mkdir -p {{TOOLS_DIR}}/phpcpd
	{{COMPOSE_COMPOSER}} require --dev sebastian/phpcpd --working-dir {{TOOLS_DIR}}/phpcpd

tools: && tools-phpmd tools-phpcs tools-phpcsfixer tools-phpstan tools-phpcpd
	{{COMPOSE_PHP}} mkdir -p {{TOOLS_DIR}}
	{{COMPOSE_PHP}} echo -e {{GITIGNORE_TEMPLATE}} >> .gitignore

new-symfony:
	{{COMPOSE_SYMFONY}} new temporary_dir
	{{COMPOSE_PHP}} rm -rf temporary_dir/.git && cp -R temporary_dir/. . && rm -rf temporary_dir
	just tools
	{{COMPOSE_COMPOSER}} install
