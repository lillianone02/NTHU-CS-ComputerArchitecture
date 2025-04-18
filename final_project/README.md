Click below to see classroom slides.

[Class Slides](https://github.com/lillianone02/NTHU-CS-ComputerArchitecture/blob/main/final_project/Final_Project_Implementation_Guide.pdf)

[Class Slides](https://github.com/lillianone02/NTHU-CS-ComputerArchitecture/blob/main/final_project/Final_project_Notice.pdf)

# 🧠 Cache Simulator Final Project

This project implements a **cache simulator** with support for both **basic indexing** and **advanced dynamic indexing** strategies, using the **1-bit Clock Replacement policy**.

---

## 📌 Features

- Supports both **Basic** and **Advanced** index selection methods.
- Simulates memory access with **clock-based replacement policy**.
- Provides **hit/miss reporting** and **cache statistics output**.

---

## 🔁 Algorithm Overview

### Basic Mode:
- Uses consecutive bits (LSB) as index.
- Fixed mapping and simpler logic.
- Suitable for straightforward simulations.

### Advanced Mode:
- Dynamically selects index bits based on:
  - **Information Gain Ratio** (Q matrix)
  - **Bit Correlation Matrix** (C matrix)
- Adapts to memory access patterns for better cache performance.

---

## 🗂️ Input Files

- `cache_config.txt`: Contains cache parameters like `block_size`, `address_bits`, etc.
- `reference_list.txt`: Memory address access sequence.

---

## 📤 Output

- `result.txt`: Simulation results including:
  - Cache hit/miss results
  - Index bit choices
  - Overall statistics

---

## 🛠️ How to Run

1. Implement all TODOs in the provided C++ template.
2. Compile using `g++` or other C++ compilers.
3. Run with:
   ```bash
   ./cache_simulator config.txt trace.txt output.txt

