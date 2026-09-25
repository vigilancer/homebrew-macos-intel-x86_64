# manage

Обновляет соседнюю репу `../brew`: ставит её `master` на последний тег [Homebrew/brew](https://github.com/Homebrew/brew) и накладывает наш патч.

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
3. Если родитель текущего `HEAD` уже этот тег, печатает `brew is already … plus patch` и выходит.
4. Иначе переводит `master` репы `../brew` на тег, накладывает `unsupported-os.patch`, делает коммит `Apply unsupported-os.patch on <тег>`.
5. Подтягивает этот коммит в подмодуль `manage/brew` и коммитит указатель здесь.

Повторный запуск на том же теге ничего не меняет.

## Посмотреть, на чём стоим

```sh
git -C ../brew log --oneline
git -C ../brew status -sb
```

Ожидаются два коммита: тег апстрима (`grafted`) и коммит с патчем. Полной истории Homebrew в клоне нет, её обрезал `--depth 1`.

## Поменять патч

1. Отредактировать `unsupported-os.patch`.
2. В `../brew` сбросить `master` на коммит тега, не на коммит с патчем: `git -C ../brew reset --hard HEAD^`.
3. Запустить `./update`. Он увидит, что родитель `HEAD` уже не тег, и наложит патч заново.

Если `git apply` упал, патч не совпал с новым тегом. Править `unsupported-os.patch` по конфликту и снова `./update` после `git -C ../brew reset --hard` на тег.

## Что сейчас запускает обычный `brew`

Файл `~/.homebrew/brew.env`:

```text
HOMEBREW_BREW_GIT_REMOTE=/Users/ae/Projects/brew
HOMEBREW_SHUT_UP_ABOUT_UNSUPPORTED_OS=1
```

Рабочий Homebrew — старый клон `/Users/ae/Projects/brew`, не эти репы. `HOMEBREW_SHUT_UP_ABOUT_UNSUPPORTED_OS=1` гасит предупреждение там.

`brew update` без developer-режима переключается не на `master`, а на старший локальный тег `X.Y.Z`. Коммит с патчем, который лежит поверх тега, update не выберет. Поэтому просто сменить `HOMEBREW_BREW_GIT_REMOTE` на `~/projects/brew-self/brew` нельзя: update снимет патч и встанет на голый тег.
