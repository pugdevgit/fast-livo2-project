#!/usr/bin/env python3
import rospy
import time
from geometry_msgs.msg import Twist

rospy.init_node('drive_square')
pub = rospy.Publisher('/cmd_vel', Twist, queue_size=10)
rate = rospy.Rate(10)

def drive(linear, angular, duration):
    twist = Twist()
    twist.linear.x = linear
    twist.angular.z = angular
    end = time.time() + duration
    while time.time() < end and not rospy.is_shutdown():
        pub.publish(twist)
        rate.sleep()

while not rospy.is_shutdown():
    drive(0.4, 0.0, 8)
    drive(0.0, 0.5, 3)
    drive(0.4, 0.0, 8)
    drive(0.0, 0.5, 3)
    drive(0.4, 0.0, 8)
    drive(0.0, 0.5, 3)
    drive(0.4, 0.0, 8)
    drive(0.0, 0.5, 3)
