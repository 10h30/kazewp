# **CaddyWP**

**CaddyWP** is an open-source tool designed to simplify the deployment and management of multiple WordPress sites behind a Caddy reverse proxy. It uses Docker and Bash scripts to automate configuration, allowing you to easily set up and scale your WordPress instances with minimal hassle.

---

## **Features**

- **Multiple WordPress Sites**: Manage as many WordPress sites as you want, all running on a single reverse proxy server.
- **Caddy Integration**: Seamlessly integrates Caddy as the reverse proxy for efficient traffic routing and SSL management.
- **Dockerized**: Fully containerized environment for easy setup and management.
- **Bash Automation**: Automate your WordPress site configurations using simple Bash scripts.
- **Scalable**: Easily add new sites and scale your infrastructure as needed.

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
   git clone https://github.com/your-username/caddywp.git
   cd caddywp
   ```

2. **Run the install script**:
   ```bash
   ./install.sh
   ```

## How It Works

Caddy: Serves as a reverse proxy, automatically obtaining SSL certificates and routing traffic to the correct WordPress container.

WordPress: Each WordPress site is hosted in its own Docker container, ensuring that each site runs in isolation with its own environment and database.

MariaDB: A single MariaDB container serves as the database for all WordPress sites. Each site uses a unique database user and password.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
Acknowledgements

    Caddy: https://caddyserver.com/
    WordPress: https://wordpress.org/
    Docker: https://www.docker.com/
    MariaDB: https://mariadb.org/

<p align="right">(<a href="#top">back to top</a>)</p>
