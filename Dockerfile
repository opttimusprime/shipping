# ============================================================
# Stage 1: Build Stage
# ============================================================

# Use Maven with Java 8 to build the Shipping application
# Java 8 is specified in the application's pom.xml
FROM maven:3.9-eclipse-temurin-8 AS builder

# Set the working directory inside the build container
WORKDIR /app

# Copy the Maven configuration file from the local repository
COPY app/pom.xml .

# Download the required Maven dependencies
# -B enables non-interactive batch mode, suitable for CI/CD
# Copying pom.xml separately helps reuse the Docker build cache
RUN mvn dependency:go-offline -B

# Copy the Java application source code into the build container
COPY app/src/ src/

# Remove previous build artifacts and package the application
# -DskipTests skips test execution during the Docker build
# Generates /app/target/shipping-1.0.jar
RUN mvn clean package -DskipTests


# ============================================================
# Stage 2: Runtime Stage
# ============================================================

# Use a lightweight Java 8 runtime image
# Maven and Java development tools are not required at runtime
FROM eclipse-temurin:8-jre

# Set the application working directory
WORKDIR /app

# Create a system group and a non-root application user
# Running the application as a non-root user improves security
RUN groupadd -r roboshop && \
    useradd -r -g roboshop roboshop

# Copy only the compiled JAR file from the build stage
# Rename shipping-1.0.jar to shipping.jar
# Assign ownership to the roboshop user and group
COPY --from=builder --chown=roboshop:roboshop \
    /app/target/shipping-1.0.jar /app/shipping.jar

# Switch from the root user to the roboshop application user
USER roboshop

# Document the port on which the Shipping application listens
EXPOSE 8080

# Start the Shipping Java application when the container starts
ENTRYPOINT ["java", "-jar", "/app/shipping.jar"]