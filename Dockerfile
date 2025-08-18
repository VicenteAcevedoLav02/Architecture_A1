FROM elixir:1.18-alpine

RUN apk add --no-cache git build-base openssl ncurses-libs

WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

COPY . /app

RUN mix deps.get

RUN mix compile

EXPOSE 4000

CMD ["mix", "phx.server"]
