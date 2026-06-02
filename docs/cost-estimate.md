# Оценка стоимости UniJobs

Оценка актуальна для serverless production-схемы:

- Yandex API Gateway принимает все HTTPS-запросы и маршрутизирует static UI в Object Storage, а `/api/*` — в Serverless Container.
- Backend работает в Yandex Serverless Containers: `512 MiB`, `1 core`, `core_fraction = 50`.
- База данных — Serverless YDB в on-demand режиме.
- Frontend releases хранятся в Object Storage `STANDARD`.

Цены взяты из документации Yandex Cloud, обновленной в мае 2026:

- Serverless Containers: 3,79 ₽ за 1 ГБ×час RAM, 5,69 ₽ за 1 vCPU×час, 18,97 ₽ за 1 млн вызовов сверх free tier.
- API Gateway: 142,3 ₽ за 1 млн HTTPS-запросов сверх free tier.
- Object Storage STANDARD: 2,376 ₽ за 1 ГБ×месяц сверх free tier, 0,46 ₽ за 10 000 GET сверх free tier, исходящий трафик сверх 100 ГБ — 1,67994 ₽/ГБ до 1 ТБ.
- Serverless YDB: on-demand запросы считаются в RU; 24,64 ₽ за 1 млн RU сверх free tier.

## Как считались запросы

Я проверил локальный UI через браузер. В dev-режиме Vite создает десятки static-запросов к modules, поэтому static-часть нельзя напрямую переносить в production: production build собирается в `index.html` и один основной JS asset.

Для production-модели используется DAU:

| Метрика | Значение на 1 DAU в день | Почему |
| --- | --- | --- |
| Static-запросы через API Gateway | 5 | `index.html`, JS bundle, assets/service files с запасом |
| Backend API-запросы через API Gateway | 20 | list vacancies, search/filter, pagination, vacancy detail, auth, application checks, my applications, create/update/delete application |
| Всего API Gateway HTTPS-запросов | 25 | static + backend API |
| YDB usage | 10 RU на backend API-запрос | учебная оценка для простых CRUD/list/detail запросов |
| Backend duration | 2 секунды на backend API-запрос | намеренно пессимистично: каждый запрос считается как cold start |
| Frontend egress | 1 МБ на DAU в день | compressed UI bundle + HTML/assets с запасом |

Формулы на месяц:

```text
gateway_requests = DAU × 25 × 30
backend_calls    = DAU × 20 × 30
ydb_ru           = backend_calls × 10
container_gb_h   = backend_calls × 0,5 GB × 2 s / 3600
container_cpu_h  = backend_calls × 0,5 vCPU × 2 s / 3600
storage_get      = DAU × 5 × 30
egress_gb        = DAU × 1 MB × 30 / 1024
```

## Измерения после деплоя

После первого production-деплоя я проверил фактическую demo-нагрузку по Cloud Logging:

```bash
yc logging read --group-id e23vvdes9u8d4h16fdq4 --limit 200 --format json
```

В этой выборке было:

| Метрика | Значение |
| --- | --- |
| API Gateway backend API-запросы | 37 |
| API Gateway static-запросы | 0 |
| Средняя длительность API Gateway | 1,431 с |
| Максимальная длительность API Gateway | 7,914 с |
| Serverless Container REPORT events | 38 |
| Среднее billed duration контейнера | 1 039,5 мс |
| Максимальное billed duration контейнера | 7 200 мс |
| Максимальная память контейнера | 237 МБ |

Это полезная проверка порядка величин: backend укладывается в `512 MiB`, а средний billed duration на короткой demo-выборке оказался ниже пессимистичных `2s` на каждый backend-запрос. Но выборка маленькая и не является billing-отчетом, поэтому расчет ниже оставлен намеренно консервативным.

Точные Yandex Monitoring/billing-метрики в текущем окружении не выгружались: установленный `yc` CLI не содержит группы команд `monitoring` (`yc monitoring metric list` возвращает `Unknown command`).

## Free tier и почти нулевая стоимость

По запрошенным сервисам каждый месяц не тарифицируется:

| Сервис | Бесплатный объем в месяц |
| --- | --- |
| Serverless Containers | 1 000 000 вызовов, 10 ГБ×час RAM, 5 vCPU×час CPU |
| API Gateway | 100 000 HTTPS-запросов |
| Object Storage STANDARD | 1 ГБ хранения, 10 000 PUT/POST/PATCH/LIST, 100 000 GET/HEAD/OPTIONS |
| Object Storage egress | 100 ГБ исходящего трафика |
| Serverless YDB | 1 000 000 RU и примерно 1 ГБ хранения |

При модели `25 gateway requests / DAU / day` главный бесплатный лимит — API Gateway:

```text
100 000 free gateway requests / (25 × 30) ≈ 133 DAU
```

YDB free tier при `20 API × 10 RU × 30` дает:

```text
1 000 000 free RU / (20 × 10 × 30) ≈ 166 DAU
```

CPU free tier для контейнера при `0,5 vCPU × 2s` дает:

```text
5 free vCPU×h / (20 × 30 × 0,5 × 2 / 3600) ≈ 30 DAU
```

RAM free tier для контейнера при `0,5 GB × 2s` дает:

```text
10 free GB×h / (20 × 30 × 0,5 × 2 / 3600) ≈ 60 DAU
```

Значит в пессимистичной модели UniJobs будет стоить **0 или почти 0 ₽/мес примерно до 30 DAU**. После этого первым начинает тарифицироваться CPU time Serverless Containers. API Gateway free tier закончится примерно на 133 DAU, YDB free tier — примерно на 166 DAU.

## 100 DAU

Условия:

- 3 000 user-days/мес;
- 75 000 API Gateway HTTPS-запросов;
- 60 000 backend вызовов;
- 600 000 RU YDB;
- 15 000 Object Storage GET;
- около 3 ГБ egress.

Расчет:

| Сервис | Расчет | Стоимость |
| --- | --- | --- |
| API Gateway | 75 000 < 100 000 free tier | 0 ₽ |
| Serverless Containers RAM | `(16,67 - 10) × 3,79` | ~25,28 ₽ |
| Serverless Containers CPU | `(16,67 - 5) × 5,69` | ~66,39 ₽ |
| Serverless Containers calls | 60 000 < 1 000 000 free tier | 0 ₽ |
| Serverless YDB | 600 000 RU < 1 000 000 free tier | 0 ₽ |
| Object Storage | 15 000 GET, < 1 ГБ storage, 3 ГБ egress | 0 ₽ |

Итого по основным runtime-сервисам: **около 92 ₽/мес**.

## 1 000 DAU

Условия:

- 30 000 user-days/мес;
- 750 000 API Gateway HTTPS-запросов;
- 600 000 backend вызовов;
- 6 000 000 RU YDB;
- 150 000 Object Storage GET;
- около 30 ГБ egress.

Расчет:

| Сервис | Расчет | Стоимость |
| --- | --- | --- |
| API Gateway | `(750 000 - 100 000) / 1 000 000 × 142,3` | ~92,50 ₽ |
| Serverless Containers RAM | `(166,67 - 10) × 3,79` | ~593,78 ₽ |
| Serverless Containers CPU | `(166,67 - 5) × 5,69` | ~919,89 ₽ |
| Serverless Containers calls | 600 000 < 1 000 000 free tier | 0 ₽ |
| Serverless YDB | `(6 000 000 - 1 000 000) / 1 000 000 × 24,64` | ~123,20 ₽ |
| Object Storage GET | `(150 000 - 100 000) / 10 000 × 0,46` | ~2,30 ₽ |
| Object Storage egress | 30 ГБ < 100 ГБ free tier | 0 ₽ |

Итого по основным runtime-сервисам: **около 1 732 ₽/мес**.

## 10 000 DAU

Условия:

- 300 000 user-days/мес;
- 7 500 000 API Gateway HTTPS-запросов;
- 6 000 000 backend вызовов;
- 60 000 000 RU YDB;
- 1 500 000 Object Storage GET;
- около 300 ГБ egress.

Расчет:

| Сервис | Расчет | Стоимость |
| --- | --- | --- |
| API Gateway | `(7 500 000 - 100 000) / 1 000 000 × 142,3` | ~1 053,02 ₽ |
| Serverless Containers RAM | `(1 666,67 - 10) × 3,79` | ~6 278,78 ₽ |
| Serverless Containers CPU | `(1 666,67 - 5) × 5,69` | ~9 455,89 ₽ |
| Serverless Containers calls | `(6 000 000 - 1 000 000) / 1 000 000 × 18,97` | ~94,85 ₽ |
| Serverless YDB | `(60 000 000 - 1 000 000) / 1 000 000 × 24,64` | ~1 453,76 ₽ |
| Object Storage GET | `(1 500 000 - 100 000) / 10 000 × 0,46` | ~64,40 ₽ |
| Object Storage egress | `(300 - 100) × 1,67994` | ~335,99 ₽ |

Итого по основным runtime-сервисам: **около 18 736 ₽/мес**.

## 50 000 DAU

Условия:

- 1 500 000 user-days/мес;
- 37 500 000 API Gateway HTTPS-запросов;
- 30 000 000 backend вызовов;
- 300 000 000 RU YDB;
- 7 500 000 Object Storage GET;
- около 1 500 ГБ egress.

Расчет без точного учета tiered egress выше 1 ТБ:

| Сервис | Расчет | Стоимость |
| --- | --- | --- |
| API Gateway | `(37 500 000 - 100 000) / 1 000 000 × 142,3` | ~5 322 ₽ |
| Serverless Containers RAM | `(8 333,33 - 10) × 3,79` | ~31 548 ₽ |
| Serverless Containers CPU | `(8 333,33 - 5) × 5,69` | ~47 388 ₽ |
| Serverless Containers calls | `(30 000 000 - 1 000 000) / 1 000 000 × 18,97` | ~550 ₽ |
| Serverless YDB | `(300 000 000 - 1 000 000) / 1 000 000 × 24,64` | ~7 367 ₽ |
| Object Storage GET | `(7 500 000 - 100 000) / 10 000 × 0,46` | ~340 ₽ |
| Object Storage egress | 1 500 ГБ требует расчета по актуальным tiered-тарифам; первые 100 ГБ free | отдельно |

Итого без egress: **около 92 855 ₽/мес**. На такой нагрузке static traffic лучше выносить за CDN/cache, а backend latency нужно оптимизировать: пессимистичная модель `2s на каждый запрос` становится основной статьей расходов.

## Рекомендации по экономии

- В пессимистичной модели главный ранний лимит free tier — CPU time Serverless Containers. Для полностью бесплатного demo держать сценарии примерно до 30 DAU или измеренно снижать cold start/latency.
- Не включать provisioned instances у Serverless Containers, пока cold start не стал измеренной проблемой: подготовленные экземпляры тарифицируются за простой.
- Держать `core_fraction = 50` и `512 MiB` для demo/backend, пока p95 latency и memory metrics не требуют увеличения.
- Чистить старые frontend releases в Object Storage, чтобы оставаться в пределах 1 ГБ free tier.
- Уменьшать лишние backend calls: кэшировать справочники на frontend, не дублировать initial fetch в production, аккуратно работать с polling.
- При росте static traffic подключить CDN и кэширование, чтобы снизить latency и нагрузку на Object Storage/API Gateway.
- Следить за YDB RU: добавить индексы только после измерения запросов, потому что индексы увеличивают storage и могут влиять на RU.
- Удалять старые backend image tags в Container Registry.
- Ограничить retention Cloud Logging, сейчас log group хранит логи 168 часов.
