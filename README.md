# Live Match Commentary System

This project is a MATLAB-based, bilingual predictive text application designed for live football (soccer) match commentary. It features a custom-built N-gram language model that provides real-time word suggestions in both English and Khmer to help commentators quickly log match events.

---

## Features

* **Bilingual Support:** Seamlessly switch between English and ភាសាខ្មែរ (Khmer) interfaces.
* **Predictive Text Engine:** Utilizes a strict tri-gram selection engine with bigram and global fallbacks to predict the next logical word in a commentary sequence.
* **Live Interactive UI:** A responsive MATLAB `uifigure` interface that updates text suggestions instantly as you type.
* **Instant Language Switching:** Toggle between English and Khmer language models on the fly without restarting the application.

---

## Prerequisites

To run this project, you will need:

* **MATLAB:** Installed on your machine (R2018a or newer is recommended for full `uifigure` component support).
* **Training Data Files:** The script trains its predictive engine locally on startup. It requires two text files to be present in the same directory as the `.m` file:
    * `data_english.txt`
    * `data_khmer.txt`

> **Note:** The application will return an initialization error if these text files are missing. Ensure they contain ample sample commentary text (e.g., historical match logs) for the predictive engine to function accurately.

---

## Installation & Setup

1.  Clone or download this repository to your local machine.
2.  Ensure `project.m`, `data_english.txt`, and `data_khmer.txt` are placed together in the same working directory.
3.  Open MATLAB and navigate to the folder containing the project files.
4.  Run the script by typing `project` in the MATLAB Command Window or by opening the script and clicking the **Run** button.

---

## Usage Guide

1.  **Select Language:** Upon launch, a startup screen will prompt you to choose your initial language (English or Khmer). The app will briefly load the data models into memory.
2.  **Type Commentary:** Begin typing in the input field. As you type, the system analyzes your input to predict what word comes next.
3.  **Use Suggestions:** Click on the suggested word buttons located directly above the input field to instantly append them to your current text block.
4.  **Submit Play:** Click **Send** (or បញ្ជូន) to move your current text into the main, non-editable commentary feed.
5.  **Clear Match:** Click **Clear Match** (or លុបការប្រកួត) to reset the UI and start a fresh commentary log.
6.  **Switch Language:** Use the button in the top right corner to instantly toggle the UI theme and background predictive model.

---

## Technical Overview

The background engine builds a localized N-gram language model upon initialization:
* **Data Parsing:** It reads the raw text files, converts them to lowercase, and strips out all punctuation to map words seamlessly across lines.
* **Trigram Logic (Primary):** If two previous words exist in the input field, the engine queries a Trigram Map to predict the statistically most likely third word.
* **Bigram Logic (Fallback):** If only one word is present, it uses a co-occurrence matrix to guess the next logical word.
* **Global Logic (Fallback):** If the input field is entirely empty, the engine suggests the most frequently used words in the respective dataset.

# Live-match-commentary---prediction
