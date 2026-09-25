# manage

## TL;DR

### Обновить git нашего brew на новый тег апстрима

```sh
cd ~/projects/brew-self/manage
./update
```

Это репа `~/projects/brew-self/brew`. Скрипт ставит `master` на последний тег апстрима, накладывает патч и переносит этот же тег `X.Y.Z` на коммит с патчем. Аннотация тега (`git show <тег>`) содержит старый SHA: fetch забирает этот объект, так что видно, что тег подвинули нарочно. В `git log` отдельной записи о сдвиге ref нет — git так не умеет.

### Подхватить это установленным brew

Когда `HOMEBREW_BREW_GIT_REMOTE` указывает на `~/projects/brew-self/brew`:

```sh
brew update
```

Update забирает теги с `--force` и переключается на старший `X.Y.Z`. Этот тег указывает на коммит с патчем. Флаг `HOMEBREW_SHUT_UP_ABOUT_UNSUPPORTED_OS=1` в `~/.homebrew/brew.env` при этом уже должен стоять.

### Новая машина: начать пользоваться нашим brew

Репы должны быть доступны по `git://git.caprica/brew/brew` и `git://git.caprica/brew/manage`.

```sh
mkdir -p ~/projects/brew-self
git clone git://git.caprica/brew/brew ~/projects/brew-self/brew
git clone git://git.caprica/brew/manage ~/projects/brew-self/manage
cd ~/projects/brew-self/manage
git submodule update --init
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

Эта репа обновляет соседнюю `../brew`: `master` становится последним тегом [Homebrew/brew](https://github.com/Homebrew/brew) плюс наш патч.

Каталог:

```text
~/projects/brew-self/brew     репа brew, origin git://git.caprica/brew/brew
~/projects/brew-self/manage   эта репа, origin git://git.caprica/brew/manage
```

`brew` внутри `manage` — подмодуль той же репы `../brew`.

## Зачем

Homebrew на Intel печатает предупреждение, что платформа не поддерживается. Текст зашит локально в `check_for_unsupported_macos`, это не ответ сервера bottle.

Патч добавляет переменную `HOMEBREW_SHUT_UP_ABOUT_UNSUPPORTED_OS`. Если она непустая, проверка выходит сразу и предупреждение не печатается. Другого поведения Homebrew патч не меняет.

Файл патча: `unsupported-os.patch`. Его и правят, если предупреждение нужно поменять.

## Обновить brew на новый тег

Из этой репы:

```sh
./update
```

Скрипт сам делает следующее.

1. Смотрит теги `https://github.com/Homebrew/brew` и берёт старший вида `X.Y.Z`. Суффиксы вроде `7.0.6-1` не считаются.
2. Качает в `../brew` только этот коммит (`git fetch --depth 1`). Родителей нет, в `git log` тег помечен `grafted`.
3. Если `HEAD` уже коммит с патчем и тег `X.Y.Z` указывает на него, печатает `brew is already … plus patch` и выходит.
4. Иначе переводит `master` на коммит апстрима, накладывает `unsupported-os.patch` и коммитит.
5. Делает аннотированный `git tag -f -a X.Y.Z` на этот коммит. Сообщение тега: с какого SHA его перенесли.
6. Подтягивает коммит и тег в подмодуль `manage/brew` и коммитит указатель здесь.

Повторный запуск на том же теге ничего не меняет.

## Сдвиг тега

Новый тег мы не заводим. `./update` переносит тот же `X.Y.Z`, который пришёл из Homebrew, на наш коммит:

```sh
git tag -f -a 7.0.6 HEAD -m "Move tag 7.0.6 from <старый SHA> onto the unsupported-os patch."
```

`-f` двигает уже существующее имя. `-a` пишет отдельный объект тега: кто, когда и с какого SHA его перенесли. `fetch` забирает этот объект вместе с коммитом.

В `git log` объекта нет. Лог показывает только коммиты. Рядом с нашим коммитом может стоять пометка `tag: 7.0.6`, это декорация, не запись о сдвиге. Текст «тег перенесли с такого-то SHA» смотреть так:

```sh
git -C ../brew show 7.0.6
```

Сначала идёт аннотация тега, ниже коммит, на который он сейчас указывает. Reflog сюда не входит: он локальный и при pull не передаётся.

## Посмотреть, на чём стоим

```sh
git -C ../brew log --oneline
git -C ../brew status -sb
```

Ожидаются два коммита: коммит апстрима (`grafted`) и коммит с патчем. Тег `X.Y.Z` стоит на втором. `git show <тег>` показывает аннотацию со старым SHA. Полной истории Homebrew в клоне нет, её обрезал `--depth 1`.

## Поменять патч

1. Отредактировать `unsupported-os.patch`.
2. В `../brew` сбросить `master` на коммит апстрима, не на коммит с патчем: `git -C ../brew reset --hard HEAD^`.
3. Запустить `./update`. Он наложит патч заново и снова перенесёт тег.

Если `git apply` упал, патч не совпал с новым тегом. Править `unsupported-os.patch` по конфликту и снова `./update` после `git -C ../brew reset --hard` на тег.

## Эта машина сейчас

`~/.homebrew/brew.env` всё ещё указывает на старый клон `/Users/ae/Projects/brew`, не на `~/projects/brew-self/brew`. Флаг `HOMEBREW_SHUT_UP_ABOUT_UNSUPPORTED_OS=1` гасит предупреждение там. Чтобы перейти на репы из этого каталога, сделать шаги из TL;DR «Новая машина», начиная с `brew.env`.
