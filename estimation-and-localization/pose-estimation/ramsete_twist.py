#!/usr/bin/env python3

"""Runs Ramsete simulation on decoupled model and compares odometry methods."""

import math
import sys

import frccontrol as fct
import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np

from bookutil import latex
from bookutil.drivetrain import get_diff_vels, ramsete
from bookutil.pose2d import Pose2d
from bookutil.systems import DrivetrainDecoupledVelocity
from bookutil.twist2d import Twist2d

if "--noninteractive" in sys.argv:
    mpl.use("svg")


def main():
    """Entry point."""
    dt = 0.05
    drivetrain = DrivetrainDecoupledVelocity(dt)

    ts, xprof, vprof, _ = fct.generate_s_curve_profile(
        max_v=4.0, max_a=3.5, time_to_max_a=1.0, dt=dt, goal=10.0
    )

    # Initial robot pose
    pose = Pose2d(2, 0, np.pi / 2.0)
    desired_pose = Pose2d()
    twist_pose = Pose2d(2, 0, np.pi / 2.0)

    # Ramsete tuning constants
    b = 2
    zeta = 0.7

    vl = float("inf")
    vr = float("inf")

    x_rec = []
    y_rec = []
    twist_x_rec = []
    twist_y_rec = []
    vref_rec = []
    omegaref_rec = []
    v_rec = []
    omega_rec = []
    ul_rec = []
    ur_rec = []

    # Log initial data for plots
    vref_rec.append(0)
    omegaref_rec.append(0)
    x_rec.append(pose.x)
    y_rec.append(pose.y)
    twist_x_rec.append(twist_pose.x)
    twist_y_rec.append(twist_pose.y)
    ul_rec.append(drivetrain.u[0, 0])
    ur_rec.append(drivetrain.u[1, 0])
    v_rec.append(0)
    omega_rec.append(0)

    # Run Ramsete
    next_r = np.array([[0.0], [0.0]])
    for i in range(len(ts) - 1):
        desired_pose.x = 0
        desired_pose.y = xprof[i]
        desired_pose.theta = np.pi / 2.0

        # pose_desired, v_desired, omega_desired, pose, b, zeta
        vref, omegaref = ramsete(desired_pose, vprof[i], 0, pose, b, zeta)
        vl, vr = get_diff_vels(vref, omegaref, drivetrain.rb * 2.0)
        r = next_r
        next_r = np.array([[vl], [vr]])
        drivetrain.update(r, next_r)
        vc = (drivetrain.x[0, 0] + drivetrain.x[1, 0]) / 2.0
        omega = (drivetrain.x[1, 0] - drivetrain.x[0, 0]) / (2.0 * drivetrain.rb)

        # Log data for plots
        vref_rec.append(vref)
        omegaref_rec.append(omegaref)
        x_rec.append(pose.x)
        y_rec.append(pose.y)
        twist_x_rec.append(twist_pose.x)
        twist_y_rec.append(twist_pose.y)
        ul_rec.append(drivetrain.u[0, 0])
        ur_rec.append(drivetrain.u[1, 0])
        v_rec.append(vc)
        omega_rec.append(omega)

        # Update nonlinear observer
        pose.x += vc * math.cos(pose.theta) * dt
        pose.y += vc * math.sin(pose.theta) * dt
        pose.theta += omega * dt
        twist_pose.exp(Twist2d(vc, 0, omega), dt)

    plt.figure(1)
    plt.ylabel("Odometry error (m)")
    plt.plot(ts, np.subtract(twist_x_rec, x_rec), label="Error in x")
    plt.plot(ts, np.subtract(twist_y_rec, y_rec), label="Error in y")
    plt.legend()
    plt.xlabel("Time (s)")

    if "--noninteractive" in sys.argv:
        latex.savefig("ramsete_twist_odometry_error")
    else:
        plt.show()


if __name__ == "__main__":
    main()
