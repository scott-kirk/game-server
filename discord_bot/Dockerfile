####################################################################################################
## Builder
####################################################################################################
FROM rust:latest AS builder

ARG TARGET="armv7-unknown-linux-gnueabihf"
ARG APP_NAME="discord_bot"
ARG GITHUB_SSH_KEY=""
RUN apt-get update
RUN apt-get install g++-arm-linux-gnueabihf libc6-dev-armhf-cross -y
RUN rustup target add $TARGET
RUN mkdir /usr/src/$APP_NAME
WORKDIR /usr/src/$APP_NAME

ENV CARGO_TARGET_ARMV7_UNKNOWN_LINUX_GNUEABIHF_LINKER=arm-linux-gnueabihf-gcc \
    CC_armv7_unknown_linux_gnueabihf=arm-linux-gnueabihf-gcc \
    CXX_armv7_unknown_linux_gnueabihf=arm-linux-gnueabihf-g++

COPY Cargo.toml ./
COPY ./src ./src

RUN cargo build --release --target=$TARGET
RUN groupadd -g 10001 -r $APP_NAME
RUN useradd -r -g $APP_NAME -u 10001 $APP_NAME

####################################################################################################
## Final image
####################################################################################################
FROM arm32v7/debian
ARG APP_NAME="discord_bot"
ARG TARGET="armv7-unknown-linux-gnueabihf"
COPY --from=builder /usr/src/$APP_NAME/target/$TARGET/release/$APP_NAME /discord_bot

CMD ["/discord_bot"]
