# ComputerCraft Automated Reactor Controller

Easily automate your Big/Bigger/Extreme reactor with a pretty graphical UI. <br />

## Features:
  <bl>
  <li>One line installer</li>
  <li>Modular displays</li>
  <li>Tested recently on Extreme / Bigger Reactors</li>
  </bl>
  
## Installation:
  To install, place and connect an Advanced Computer to a valid Reactor's Computer Port, <br />
    either with wired modems or directly on it. Then, follow these steps:
  <ol>
    <li>Run the following command in the Computer: <br />
      <code>pastebin run kSkwEchg</code>
    </li>
    <li>Choose whether to calibrate or not. The calibration is only used if using Big Reactors. It gets an estimate of the RF capacity of your reactor.</li>
  </ol>

## Configuration:
  To configure the program, use monitors. Once it is configured,
  the monitors are no longer necessary but can still display information. <br /><br />
  The minimum monitor size is 2x2. Use a height of 4 to have access to all settings. <br />
  When the monitor is 4 blocks tall, there will be the option to change graphs. <br />
  If there is not enough space to display a graph you will be unable to enable it.
## Screenshots:
![2021-05-24_20 29 15](https://user-images.githubusercontent.com/18647702/119422445-19adba00-bccf-11eb-95db-68c728e72555.png)
![2021-05-24_20 29 36](https://user-images.githubusercontent.com/18647702/119422446-1a465080-bccf-11eb-85c4-6e60e31b2869.png)
![2021-05-24_20 30 04](https://user-images.githubusercontent.com/18647702/119422448-1a465080-bccf-11eb-8c5d-f479c263da62.png)
![2021-05-24_20 30 35](https://user-images.githubusercontent.com/18647702/119422461-25997c00-bccf-11eb-9be3-9b2ad6b355bf.png)
![2021-05-24_20 30 13](https://user-images.githubusercontent.com/18647702/119422464-27fbd600-bccf-11eb-8a38-61909bb6aae8.png)

## Known Issues:
- If the reactor has a very large max RF/t generation capacity but a low RF/t drain, it may oscillate around the target buffer
  - Workaround: increase the range of the buffer (usefulness will vary)
- Reactor statistics will be inaccurate for 1-2s of power up
  
## Update History:
Last update: 12/04/2023 <p>
  <b>12/04/2023:</b> Changed Control rod insertion logic to use a PID controller <p>
  <b>5/24/2021:</b> Added support for Extreme Reactors and Big Reactors <p>
  <b>5/24/2021:</b> Started tracking update history / Uploaded to GitHub <p>

## Attributions:
<ul>
  <li><b>Krakaen: </b><br />
    Gui design influenced by Krakaen's Reactor Program <br />
    http://www.computercraft.info/forums2/index.php?/topic/26019-big-reactors-automatic-control-program/ </li>
  <li><b>Lyqyd: </b><br />
    Buttons use Touchpoint API, though one line was modified <br />
    http://www.computercraft.info/forums2/index.php?/topic/14784-touchpoint-api/ </li>
  <li><b>Immibis: </b><br />
    Thread API to detect monitor size changes<br />
    http://www.computercraft.info/forums2/index.php?/topic/3479-basic-background-thread-api/ </li>
  <li><b>Eniallator: </b><br />
    Updater script to automatically roll out changes to users <br />
  http://www.computercraft.info/forums2/index.php?/topic/25101-program-automatic-updater/" </li>
 </ul>
