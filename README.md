# Keizer et al. – Live-cell micromanipulation of a genomic locus reveals interphase chromatin mechanics

-------------
Data, software and documentation to reproduce the results from [Keizer et al](https://www.biorxiv.org/content/10.1101/2021.04.20.439763v1).

## Authors
Veer I. P. Keizer<sup>1,2,3,\#</sup>, Simon Grosse-Holz<sup>4</sup>, Maxime Woringer<sup>1,2</sup>, Laura Zambon<sup>1,2,3</sup>, Koceila Aizel<sup>2</sup>, Maud Bongaerts<sup>2</sup>, Lorena Kolar-Znika<sup>1,2</sup>, Vittore F. Scolari<sup>1,2</sup>, Sebastian Hoffmann<sup>3</sup>, Edward J. Banigan<sup>4</sup>, Leonid A. Mirny<sup>4</sup>, Maxime Dahan<sup>2,§</sup>, Daniele Fachinetti<sup>3,\*</sup>, Antoine Coulon<sup>1,2,\*,¶</sup>

**1\.** Institut Curie, PSL Research University, Sorbonne Université, CNRS UMR3664, Laboratoire Dynamique du Noyau, 75005 Paris, France, **2.** Institut Curie, PSL Research University, Sorbonne Université, CNRS UMR168, Laboratoire Physico Chimie Curie, 75005 Paris, France, **3.** Institut Curie, PSL Research University, Sorbonne Université, CNRS UMR144, Laboratoire Biologie Cellulaire et Cancer, 75005 Paris, France, **4.** Department of Physics and Institute for Medical Engineering and Science, Massachusetts Institute of Technology, Cambridge, 02139 MA, USA. **\#** Present address: National Cancer Institute, NIH, Bethesda, MD, USA. **§** Deceased, **\*** Correspondence: daniele.fachinetti@curie.fr, antoine.coulon@curie.fr (**¶** Lead contact).

## Content of this repository

|Description|Location on GitHub|External link|
|---|:---:|:---:|
|**Final registered and rotated TIFF files**:<ul><li>All 8 cells analyzed for the 30’-PR experiment</li><li>100”-PR experiment, with time projections & kymograph</li></ul>|  | [Zenodo](https://zenodo.org/record/4674438) |
|Data files with **trajectories and forces** for all analyzed cells| [`./data/2-trajectory_files/`](./data/2-trajectory_files/) | \" |
|**Fiji/Python scripts** for generating these files| [`./data/3-code_and_protocol/`](./data/3-code_and_protocol/) | \" |
| ––––––––––––––––––––––––––––––––––––––––––––––––––––––––– | ––––––––––––––––––––––––––––– | ––––––– |
|Raw spinning-disk microscopy **data for force calibration**|  | [Zenodo](https://zenodo.org/record/4627062) |
|Force maps calculated on this data|  | \" |
|**Fiji scripts** for generating these force maps| [`./forcecalibration/scripts/`](./forcecalibration/scripts/) | \" |
| ––––––––––––––––––––––––––––––––––––––––––––––––––––––––– | ––––––––––––––––––––––––––––– | ––––––– |
|Raw microscopy **data for single-MNP intensity calibration**|  | [Zenodo](https://zenodo.org/record/4674531) |
|**Fiji scripts** for generating average single-MNP image| [`./singleMNPs/analysis/`](./singleMNPs/analysis/) | \" |
| ––––––––––––––––––––––––––––––––––––––––––––––––––––––––– | ––––––––––––––––––––––––––––– | ––––––– |
|**Python pipeline for concatenating** raw microscopy images| [`CoulonLab/chromag-pipeline`](https://github.com/CoulonLab/chromag-pipeline) | [Zenodo](https://zenodo.org/record/4674417) |
|**Magnetic simulations**:<ul><li>MagSim Python library</li><li>Jupyter notebook for calibrating and generating maps</li></ul>| [`CoulonLab/MagSim`](https://github.com/CoulonLab/MagSim) | [Zenodo](https://zenodo.org/record/4672595) |
|**Python library for force inference** using polymer models| [`SGrosse-Holz/rouselib`](https://github.com/SGrosse-Holz/rouselib) | [Zenodo](https://zenodo.org/record/4674399) |

## Publication status
The study [Keizer et al.](https://www.biorxiv.org/content/10.1101/2021.04.20.439763v1) is available as a preprint. It has not yet been peer reviewed and is not yet published in a journal.

## Data re-use policy
As [standard practice in the field](https://www.4dnucleome.org/policies.html), researchers using this public, but as yet unpublished data must contact the specific data producer (antoine.coulon@curie.fr) to discuss possible coordinated publication. Unpublished data are those that have never been described and referenced by a peer-reviewed publication.

In addion to this restriction, all the code and data in this repository is under GPLv3 license (see the [`LICENSE`](LICENSE) file for details).
