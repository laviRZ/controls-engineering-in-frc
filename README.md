# Practical Guide to State-space Control
## Graduate-level control theory for high schoolers

I originally wrote this as a final project for an undergraduate technical writing class I took at University of California, Santa Cruz in Spring 2017 ([CMPE 185](https://cmpe185-spring17-01.courses.soe.ucsc.edu/)). It is intended as a digest of graduate-level control theory aimed at veteran FIRST Robotics Competition (FRC) students who know algebra and a bit of physics and are comfortable with the concept of a PID controller. As I learned the subject of control theory, I found that it wasn't particularly difficult, but very few resources exist outside of academia for learning it. This document is intended to rectify that situation by providing a lower the barrier to entry to the field.

This document reads a lot like a reference manual on control theory and related tools. It teaches the reader how to start designing and implementing control systems for practical systems with an emphasis on pragmatism rather than theory. While the theory is mathematically elegant at times and helps inform what is going on, one shouldn't lose sight of how it behaves when applied to real systems.

## Dependencies

* make (to run the makefile)
* texlive-core (for latexmk and pdflatex)
* texlive-latexextra (for bibtex and makeglossaries)
* Python 3.5+ and Python Control (to generate plots and state-space results)
* Inkscape (to convert SVGs to PDF)

## Download

A PDF version is available at https://file.tavsys.net/control/state-space-guide.pdf.

## Future Improvements

The document is still very high level for the subject it covers as well as very dense and fast-paced (it covers three classes of feedback control, two of which are for graduate students, in one short document). It's slowly getting better in that respect. I'd like to expand the introductions for each section and provide more examples like I did for the Kalman filter design to give the reader practice applying the skills discussed.

Since the link to the Wikibooks page on block diagrams only shows a table of simplification steps, that could be written in TikZ as an appendix.

The linear algebra section should be filled out with some basics that are needed
to understand the examples (how is dimensionality specified, how are matrices multiplied together as linear transformations, what are eigenvalues). Specific videos from the 3Blue1Brown playlist will be referred to for more information. Following the content of the videos in order is an option.

The referencesd derivations for the optimal control law are really just showing the cost function and what K actually is. It should be included in an appendix instead (as should any other results that are good for background, but are unnecessary).

The link to the graphical introduction to Kalman filters should be replaced with something much more comprehensive. The graphics are nice, but there isn't much substance to promote deep understanding. I have a lot of notes from the course I took on Kalman filters I intend to synthesize.

The referenced derivations for the Kalman filter could be added as an appendix since they aren't that involved.

The "Implementation Steps" section needs subsections to explain how to do each or at least examples. A small section on kinematics and dynamics in general would be useful. The following state-space implementation examples are planned:

* Elevator (in progress)
  * Add u_error state to model
  * Include discretization and controller tuning steps in Python
  * Include writing unit tests in Google Test
  * Include how to implement the model in C++ with Eigen
* Drivetrain
  * See 971/y2017/control_loops/python/drivetrain.py
  * 971/y2017/control_loops/python/polydrivetrain.py?
* Flywheel
  * See 971/y2017/control_loops/python/shooter.py
* Single-jointed arm (pulley with pitch control of bar)
* Rotating claw with independent top/bottom
  * See 971/y2014/control_loops/python/claw.py
  * Use as example of coordinate transformations for states?