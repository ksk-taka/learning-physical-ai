"""Full demo: Gazebo + TurtleBot3 + SLAM + Nav2 を一括起動.

カスタムワールド (custom_house) 内で TurtleBot3 Burger を使用。

使い方:
  export TURTLEBOT3_MODEL=burger
  ros2 launch my_robot_pkg full_demo.launch.py

  # SLAM済み地図でNav2のみ起動する場合:
  ros2 launch my_robot_pkg full_demo.launch.py slam:=false map:=/path/to/map.yaml
"""
import os

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import (
    DeclareLaunchArgument,
    IncludeLaunchDescription,
    GroupAction,
)
from launch.conditions import IfCondition, UnlessCondition
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node


def generate_launch_description():
    pkg_dir = get_package_share_directory('my_robot_pkg')
    pkg_gazebo_ros = get_package_share_directory('gazebo_ros')
    tb3_gazebo_dir = get_package_share_directory('turtlebot3_gazebo')
    nav2_bringup_dir = get_package_share_directory('nav2_bringup')

    # === Launch arguments ===
    use_sim_time = LaunchConfiguration('use_sim_time', default='true')
    slam = LaunchConfiguration('slam', default='true')
    map_file = LaunchConfiguration('map', default='')
    x_pose = LaunchConfiguration('x_pose', default='-3.0')
    y_pose = LaunchConfiguration('y_pose', default='-2.0')

    world = os.path.join(pkg_dir, 'worlds', 'custom_house.sdf')
    slam_params = os.path.join(pkg_dir, 'config', 'slam_params.yaml')
    nav2_params = os.path.join(pkg_dir, 'config', 'nav2_params.yaml')

    return LaunchDescription([
        DeclareLaunchArgument('use_sim_time', default_value='true'),
        DeclareLaunchArgument('slam', default_value='true',
                              description='Run SLAM (true) or use existing map (false)'),
        DeclareLaunchArgument('map', default_value='',
                              description='Path to map yaml for localization mode'),
        DeclareLaunchArgument('x_pose', default_value='-3.0'),
        DeclareLaunchArgument('y_pose', default_value='-2.0'),

        # === 1. Gazebo with custom world ===
        IncludeLaunchDescription(
            PythonLaunchDescriptionSource(
                os.path.join(pkg_gazebo_ros, 'launch', 'gzserver.launch.py')
            ),
            launch_arguments={'world': world}.items()
        ),
        IncludeLaunchDescription(
            PythonLaunchDescriptionSource(
                os.path.join(pkg_gazebo_ros, 'launch', 'gzclient.launch.py')
            )
        ),

        # === 2. TurtleBot3 Robot State Publisher ===
        IncludeLaunchDescription(
            PythonLaunchDescriptionSource(
                os.path.join(tb3_gazebo_dir, 'launch',
                             'robot_state_publisher.launch.py')
            ),
            launch_arguments={'use_sim_time': use_sim_time}.items()
        ),

        # === 3. Spawn TurtleBot3 in Gazebo ===
        IncludeLaunchDescription(
            PythonLaunchDescriptionSource(
                os.path.join(tb3_gazebo_dir, 'launch',
                             'spawn_turtlebot3.launch.py')
            ),
            launch_arguments={
                'x_pose': x_pose,
                'y_pose': y_pose,
            }.items()
        ),

        # === 4. SLAM (slam_toolbox) — slam:=true の場合 ===
        Node(
            condition=IfCondition(slam),
            package='slam_toolbox',
            executable='async_slam_toolbox_node',
            name='slam_toolbox',
            parameters=[slam_params, {'use_sim_time': use_sim_time}],
            output='screen'
        ),

        # === 5. Map Server — slam:=false の場合 ===
        Node(
            condition=UnlessCondition(slam),
            package='nav2_map_server',
            executable='map_server',
            name='map_server',
            parameters=[{
                'use_sim_time': use_sim_time,
                'yaml_filename': map_file,
            }],
            output='screen'
        ),
        Node(
            condition=UnlessCondition(slam),
            package='nav2_lifecycle_manager',
            executable='lifecycle_manager',
            name='lifecycle_manager_map',
            parameters=[{
                'use_sim_time': use_sim_time,
                'autostart': True,
                'node_names': ['map_server'],
            }],
            output='screen'
        ),

        # === 6. Nav2 ===
        IncludeLaunchDescription(
            PythonLaunchDescriptionSource(
                os.path.join(nav2_bringup_dir, 'launch', 'navigation_launch.py')
            ),
            launch_arguments={
                'use_sim_time': 'true',
                'params_file': nav2_params,
            }.items()
        ),

        # === 7. RViz2 ===
        Node(
            package='rviz2',
            executable='rviz2',
            arguments=['-d', os.path.join(
                nav2_bringup_dir, 'rviz', 'nav2_default_view.rviz')],
            parameters=[{'use_sim_time': use_sim_time}],
            output='screen'
        ),
    ])
