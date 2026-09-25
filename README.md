# manage

## TL;DR

### Обновить git нашего brew на новый тег апстрима

```sh
cd ~/projects/brew-self
./update
```

Скрипт создаёт локальную папку `brew/` (она в `.gitignore`, это не подмодуль), ставит её `master` на последний тег апстрима, накладывает патчи по очереди и переносит этот же тег `X.Y.Z` на последний коммит. Аннотация тега (`git show <тег>`) содержит старый SHA: fetch забирает этот объект, так что видно, что тег подвинули нарочно. В `git log` отдельной записи о сдвиге ref нет — git так не умеет.

### Подхватить это установленным brew

Когда `HOMEBREW_BREW_GIT_REMOTE` указывает на `~/projects/brew-self/brew`:

```sh
brew update
```

Update забирает теги с `--force` и переключается на старший `X.Y.Z`. Этот тег указывает на коммит с патчем. Флаг `HOMEBREW_SHUT_UP_ABOUT_UNSUPPORTED_OS=1` в `~/.homebrew/brew.env` при этом уже должен стоять.

### Новая машина: начать пользоваться нашим brew

Репа `manage` должна быть доступна по `git://git.caprica/brew/manage`. Папка `brew/` внутри неё на сервер не попадает: её создаёт `./update`.

```sh
mkdir -p ~/projects/brew-self
git clone git://git.caprica/brew/manage ~/projects/brew-self
cd ~/projects/brew-self
./update
```

Дальше указать Homebrew на этот клон и включить флаг. На Intel репа Homebrew — `/usr/local/Homebrew` (`brew --repo`).

```sh
mkdir -p ~/.homebrew
cat > ~/.homebrew/brew.env << EOF
HOMEBREW_BREW_GIT_REMOTE=$HOME/projects/brew-self/brew
HOMEBREW_SHUT_UP_ABOUT_UNSUPPORTED_OS=1
EOF

brew update
```

`./update` создаёт `brew/` рядом со скриптом. `master` в этой папке становится последним тегом [Homebrew/brew](https://github.com/Homebrew/brew) плюс наш патч. В git этой репы папка не входит.

Каталог:

```text
~/projects/brew-self        эта репа, origin git://git.caprica/brew/manage
~/projects/brew-self/brew   локальный клон, создаёт ./update, в .gitignore
```

## Зачем

Homebrew на Intel печатает предупреждение, что платформа не поддерживается. Текст зашит локально в `check_for_unsupported_macos`, это не ответ сервера bottle.

Патч добавляет переменную `HOMEBREW_SHUT_UP_ABOUT_UNSUPPORTED_OS`. Если она непустая, проверка выходит сразу и предупреждение не печатается. Другого поведения Homebrew патч не меняет.

Патчи, по порядку:

1. `patches/0001-unsupported-os.patch` — предупреждение.
2. `patches/0002-build-from-source.patch` — `HOMEBREW_BUILD_FROM_SOURCES_YOU_PHILISTINE`. Любое непустое значение заставляет `install`, `upgrade`, `reinstall` и `fetch` собирать формулу и её зависимости из исходников, даже если bottle есть. `--force-bottle` это перекрывает. Флаг `-s` по-прежнему действует только на формулы, названные в команде, и не на зависимости.
3. `patches/0003-formula-overlay.patch` — `HOMEBREW_FORMULA_OVERLAY`. Путь к папке с файлами `<имя>.rb`. Если файл есть, `brew` берёт его вместо формулы из API, и для короткого имени, и для `homebrew/core/<имя>`. Остальные формулы по-прежнему из JSON.
4. `patches/0004-forbid-casks-no-whining.patch` — у `HOMEBREW_FORBID_CASKS` стоит `odeprecated: false`. Переменная по-прежнему запрещает установку cask, предупреждение больше не печатается.

## Обновить brew на новый тег

Из этой репы:

```sh
./update
```

Скрипт сам делает следующее.

1. Смотрит теги `https://github.com/Homebrew/brew` и берёт старший вида `X.Y.Z`. Суффиксы вроде `7.0.6-1` не считаются.
2. Если папки `brew/` нет, делает в ней `git init`. Качает туда только коммит тега (`git fetch --depth 1`). Родителей нет, в `git log` тег помечен `grafted`.
3. Если тег `X.Y.Z` уже указывает на `HEAD` и этот коммит стоит поверх скачанного тега апстрима, печатает `brew is already … plus patches` и выходит.
4. Иначе переводит `master` в `brew/` на коммит апстрима, берёт все `*.patch` из `patches/`, сортирует их по номеру в начале имени и коммитит по очереди.
5. Делает аннотированный `git tag -f -a X.Y.Z` на последний коммит. Сообщение тега: с какого SHA его перенесли.

Повторный запуск на том же теге ничего не меняет.

## Сдвиг тега

Новый тег мы не заводим. `./update` переносит тот же `X.Y.Z`, который пришёл из Homebrew, на наш коммит:

```sh
git tag -f -a 7.0.6 HEAD -m "Move tag 7.0.6 from <старый SHA> onto the unsupported-os patch."
```

`-f` двигает уже существующее имя. `-a` пишет отдельный объект тега: кто, когда и с какого SHA его перенесли. `fetch` забирает этот объект вместе с коммитом.

В `git log` объекта нет. Лог показывает только коммиты. Рядом с нашим коммитом может стоять пометка `tag: 7.0.6`, это декорация, не запись о сдвиге. Текст «тег перенесли с такого-то SHA» смотреть так:

```sh
git -C brew show 7.0.6
```

Сначала идёт аннотация тега, ниже коммит, на который он сейчас указывает. Reflog сюда не входит: он локальный и при pull не передаётся.

## Посмотреть, на чём стоим

```sh
git -C brew log --oneline
git -C brew status -sb
```

Ожидаются коммит апстрима (`grafted`) и по коммиту на каждый патч. Тег `X.Y.Z` стоит на последнем. `git show <тег>` показывает аннотацию со старым SHA. Полной истории Homebrew в клоне нет, её обрезал `--depth 1`.

## Поменять патч

1. Отредактировать нужный файл в `patches/`.
2. В `brew/` сбросить `master` на скачанный коммит апстрима: `git -C brew reset --hard refs/upstream-tags/7.0.6` (подставить текущий тег).
3. Запустить `./update`. Он наложит оба патча заново и снова перенесёт тег.

Если `git apply` упал, патч не совпал с новым тегом. Править его по конфликту и снова `./update` после того же `reset --hard`.

## Эта машина сейчас

`~/.homebrew/brew.env` всё ещё указывает на старый клон `/Users/ae/Projects/brew`, не на `~/projects/brew-self/brew`. Флаг `HOMEBREW_SHUT_UP_ABOUT_UNSUPPORTED_OS=1` гасит предупреждение там. Чтобы перейти на репы из этого каталога, сделать шаги из TL;DR «Новая машина», начиная с `brew.env`.
