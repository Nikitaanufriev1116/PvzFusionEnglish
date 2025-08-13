# ChatGPT5 на GitHub Pages

Минималистичный веб-чат с потоковыми ответами. Фронтенд публикуется на GitHub Pages (статически), а ключ к API хранится на прокси (Cloudflare Worker), чтобы не светить его в браузере.

## Как развернуть

### 1) Подготовьте репозиторий
- Создайте новый репозиторий на GitHub.
- Скопируйте файлы этого проекта в корень репо, либо форкните.
- Включите GitHub Pages: Settings → Pages → Build and deployment: GitHub Actions.

GitHub Actions из `.github/workflows/pages.yml` автоматически развернут папку `site/` на Pages при пуше в ветку `main`.

### 2) Настройте Cloudflare Worker (прокси к OpenAI)
Этот worker принимает POST `/api/chat` и проксирует потоковые ответы OpenAI Chat Completions.

- Установите Wrangler (локально):
  ```bash
  npm i -g wrangler
  ```
- Перейдите в папку `worker/` и установите зависимости:
  ```bash
  cd worker
  npm i
  ```
- Войдите в Cloudflare и создайте/выберите аккаунт: `wrangler login`
- Задайте секрет с ключом OpenAI (он НЕ попадает в репозиторий):
  ```bash
  npx wrangler secret put OPENAI_API_KEY
  ```
- Задеплойте:
  ```bash
  npm run deploy
  ```
- Скопируйте URL воркера вида `https://chatgpt5-proxy.YOUR-ACCOUNT.workers.dev`.

### 3) Укажите URL прокси во фронтенде
- Скопируйте `site/config.example.js` → `site/config.js` и пропишите ваш URL:
  ```js
  window.CHATGPT5_PROXY_URL = "https://chatgpt5-proxy.YOUR-ACCOUNT.workers.dev";
  ```
- Закоммитьте изменения и запушьте в `main`. Спустя ~1 минуту сайт обновится на Pages.

### 4) Откройте сайт
- Адрес вида: `https://<ВАШ_GH_ЛОГИН>.github.io/<ИМЯ_РЕПО>/`
- Задавайте вопросы в поле ввода. Ответы приходят потоково.

## Структура
- `site/` — статический фронтенд (HTML/CSS/JS)
- `worker/` — прокси на Cloudflare Worker (CORS, потоковая прокладка к OpenAI)
- `.github/workflows/pages.yml` — автодеплой на GitHub Pages

## Важно
- Никогда не кладите ключ OpenAI в браузерный код. Храните его только в переменных окружения воркера (`OPENAI_API_KEY`).
- По умолчанию используется модель `gpt-4o-mini` (дешевле и шустро). В селекторе можно указать другую поддерживаемую модель.

## Локальная проверка фронтенда
Откройте `site/index.html` в браузере через локальный веб-сервер (например `npx serve site`) и проверьте, что `site/config.js` указывает на ваш рабочий воркер.

## Замечания о названии "ChatGPT5"
Интерфейс называется «ChatGPT5» для краткости, однако фактическая модель выбирается через селектор и может отличаться. Название не раскрывает ключ и не влияет на тарифы API.
