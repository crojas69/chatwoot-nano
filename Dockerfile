# Etapa base con Ruby y Node para compilar assets
FROM ruby:3.2.2 AS builder

# Instalar dependencias del sistema
RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  nodejs \
  yarn \
  curl \
  file \
  git \
  libvips \
  imagemagick \
  ffmpeg \
  && rm -rf /var/lib/apt/lists/*

# Establecer directorio de trabajo
WORKDIR /app

# Copiar Gemfile y Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Instalar gems
RUN gem install bundler -v 2.3.26 && bundle install --jobs 4 --retry 5

# Copiar el resto del código de la aplicación
COPY . .

# Precompilar assets
RUN RAILS_ENV=production bundle exec rake assets:precompile

# Etapa final, imagen optimizada
FROM ruby:3.2.2

LABEL maintainer="Iabot <soporte@iabot.com.co>"

# Instalar dependencias mínimas para producción
RUN apt-get update -qq && apt-get install -y \
  libpq-dev \
  nodejs \
  imagemagick \
  ffmpeg \
  libvips \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copiar archivos desde la etapa de build
COPY --from=builder /app /app

# Configurar entorno
ENV RAILS_ENV=production \
    NODE_ENV=production \
    BUNDLE_WITHOUT="development test"

# Exponer el puerto
EXPOSE 3000

# Comando por defecto al iniciar el contenedor
CMD ["bash", "-lc", "bundle exec rails s -b 0.0.0.0 -p 3000"]
