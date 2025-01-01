# **KazeWP**

**KazeWP** is an open-source tool designed to simplify the deployment and management of multiple WordPress sites behind a lightweight reverse proxy. It uses Docker and Bash scripts to automate configuration, allowing you to quickly set up and scale your WordPress instances with minimal effort.

---

## **Features**

- **Multiple WordPress Sites**: Easily manage multiple WordPress sites, each running in its own container.
- **Reverse Proxy Integration**: Leverages Caddy for efficient traffic routing and automatic SSL certificate management.
- **Containerized Environment**: Fully Dockerized for simplicity, portability, and scalability.
- **Bash Automation**: Intuitive Bash scripts automate site configuration and deployment.
- **Effortless Scaling**: Add or remove WordPress sites with ease, scaling as your needs grow.

---

## **Getting Started**

### **Prerequisites**

Ensure you have the following installed:

- [Docker](https://www.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)
- A Unix-based environment (Linux or macOS) or WSL on Windows

### **Installation**

1. **Clone the repository**:
    ```bash
    git clone https://github.com/your-username/kazewp.git
    cd kazewp
    ```

2. **Run the install script**:
    ```bash
    ./kazewp.sh install domain.com
    ```

---

## **Usage**

   ```bash
   ./kazewp.sh install <domain>  - Install a new WordPress site
   ./kazewp.sh list                          - List all installed WordPress sites
   ./kazewp.sh delete <domain>            - Delete a WordPress site
   ./kazewp.sh delete all                    - Delete everything
   ```

## **How It Works**

- **Reverse Proxy**: KazeWP uses Caddy as a reverse proxy, automatically handling SSL certificates and routing traffic to the appropriate WordPress container.
- **WordPress Isolation**: Each WordPress site runs in its own Docker container with a unique configuration.
- **Shared Database**: MariaDB serves as the database for all WordPress sites, with each site using a unique database user and password.

---

## **License**

This project is licensed under the MIT License - see the LICENSE file for details.

---

## **Acknowledgements**

- [Caddy](https://caddyserver.com/)
- [WordPress](https://wordpress.org/)
- [Docker](https://www.docker.com/)
- [MariaDB](https://mariadb.org/)

---

<p align="right">(<a href="#top">back to top</a>)</p>
