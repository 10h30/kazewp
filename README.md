# **KazeWP**

**KazeWP** is an open-source tool designed to simplify the deployment and management of multiple WordPress sites behind a lightweight reverse proxy. It uses Docker and Bash scripts to automate configuration, allowing you to quickly set up and scale your WordPress instances with minimal effort.

![KazeWP](images/kazewp.png)


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
   ./kazewp.sh install <domain>        - Install a new WordPress site
   ./kazewp.sh list                    - List all installed WordPress sites
   ./kazewp.sh delete <domain>         - Delete a WordPress site
   ./kazewp.sh delete all              - Delete everything
   ```

## **How It Works**

KazeWP simplifies the deployment and management of multiple WordPress websites by using Docker containers and Caddy as a reverse proxy. Here’s a breakdown of the key components and how they work together:

### **Caddy (Reverse Proxy)**
Caddy acts as the reverse proxy, automatically handling SSL certificate generation and secure HTTPS connections for all WordPress sites. It efficiently routes incoming traffic to the correct site based on the domain name, ensuring seamless and secure access.

### **WordPress (Site Containers)**
Each WordPress site runs in its own dedicated Docker container. This isolation ensures that each site has its own environment, minimizing the risk of conflicts between sites and making it easy to manage and update individual sites.

### **Dedicated Database (MariaDB)**
Unlike traditional setups where multiple sites share a single database, KazeWP creates a **dedicated MariaDB database** for each WordPress site. This offers several advantages:

- **Improved Isolation**: Each site operates independently with its own database, reducing the risk of cross-site issues.
- **Easier Migration**: Since each site has a self-contained database, migrating sites to a new host is straightforward and doesn’t require any reconfiguration of the shared database.
- **Better Performance**: By isolating the databases, you can better manage the performance and resources for each individual site.

### **Bash Script Automation**
KazeWP leverages Bash scripts to automate key tasks such as site creation, listing existing sites, and deleting sites. The automation ensures that you can manage your WordPress instances with minimal manual effort and reduced chances of human error.

By combining these components, KazeWP offers a fast, efficient, and scalable solution for managing multiple WordPress websites with minimal configuration.

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
