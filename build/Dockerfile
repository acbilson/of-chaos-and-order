#############
# Build
#############

FROM python:3.9.7-alpine3.14 as build

# Create the initial service artifacts.


#############
# Base
#############

FROM python:3.9.7-alpine3.14 as base

# Copy essential build artifacts for further distribution

COPY --from=build /root/.local /root/.local


#############
# Development
#############

FROM base as dev

# Set development environmental variables and configure a dev-specific entrypoint


#####
# UAT
#####

FROM base as uat

# Same as dev, but uat


############
# Production
############

FROM base as prod

# Same as uat, but prod
