FROM golang:1.24 AS builder

ARG WORKER_BINARY
ARG TARGETOS=linux
ARG TARGETARCH=arm64
WORKDIR /src

COPY go.mod ./
COPY cmd ./cmd
COPY internal ./internal

RUN test -n "${WORKER_BINARY}"
RUN CGO_ENABLED=0 GOOS="${TARGETOS}" GOARCH="${TARGETARCH}" go build -o /out/worker "./cmd/${WORKER_BINARY}"

FROM gcr.io/distroless/static-debian12:nonroot

COPY --from=builder /out/worker /worker

EXPOSE 8080
ENTRYPOINT ["/worker"]
