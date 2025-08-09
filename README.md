# ❯ AutoTools

**AutoTools** is a collection of simple, easy-to-use shell scripts to automate common tasks on Linux systems. Whether you want to manage multiple SSH connections, monitor system health, or streamline your daily workflows, AutoTools has you covered.

---

## Features

* Easy automation for repetitive Linux tasks
* Scripts designed primarily for Debian and similar distributions
* Clean, user-friendly command-line interfaces
* Save time and reduce errors with tested utilities
* Includes multi-server SSH manager using Tilix + tmux
* Easily extendable — add your own scripts or improve existing ones

---

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/fbarikzehi/auto-tools.git
   ```

2. Change directory into the cloned repo:

   ```bash
   cd auto-tools
   ```

3. Make scripts executable:

   ```bash
   chmod +x *.sh
   ```

4. (Optional) Add the directory to your PATH for easy access:

   ```bash
   echo 'export PATH=$PATH:$(pwd)' >> ~/.bashrc
   source ~/.bashrc
   ```

---

## Usage

Run any script directly from the repo folder:

```bash
./script-name.sh
```

For example, to launch the tilix-tmux multi-server SSH manager:

```bash
./tilix-tmux-multiSSH.sh
```

Each script typically includes usage instructions or prompts to guide you.

---

## Adding Your Own Scripts

Feel free to add your own automation scripts to this collection. Follow these simple guidelines:

* Use clear, descriptive script names
* Add usage instructions or help messages in the script
* Keep dependencies minimal or clearly documented
* Test thoroughly on linux or compatible systems

---

## Contribution

Contributions are welcome! To contribute:

1. Fork the repository

2. Create a new branch for your feature or fix:

   ```bash
   git checkout -b feature-name
   ```

3. Make your changes and commit with descriptive messages

4. Push your branch to your fork

5. Open a Pull Request describing your changes

We appreciate bug reports, feature requests, and improvements.

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

Happy automating! 🚀
