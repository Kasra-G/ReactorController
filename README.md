# ComputerCraft Automated Reactor Controller

Easily automate your Bigger/Extreme reactor with a pretty graphical UI. <br />

## Features
  <bl>
  <li>One line installation</li>
  <li>Modular displays to customize information shown</li>
  <li>Automatically control your reactor with optional configuration</li>
  <li>Tested on Extreme and Bigger Reactors</li>
  </bl>

## Turbine support??
Not yet. Check out this script if you want a nice script with turbine support. <br />
https://gitlab.com/seekerscomputercraft/extremereactorcontrol/

I do want to eventually add turbine support, but it will take me some time to implement it, make sure the changes are backwards compatible, and then create the UI for it. I also work full time now, so time is much more sparse.
## Installation
  <ol>
    <li>
      Connect an Advanced Computer directly to a reactor or via wired modem network
    </li>
    <li>
      Optionally, you can connect a monitor. Connect it directly to the computer or via wired modem network
    </li>
    <li>
       Make sure that all modems are activated
    </li>
    <li>
      Run the following command in the Computer: <br />
      <code>pastebin run kSkwEchg</code>
    </li>
  </ol>

## Configuration
  To configure the program, use monitors. Once it is configured,
  the monitors are no longer necessary but can still display information. <br /><br />
  The minimum monitor size is 2x2. Use a height of 4 to have access to all settings. <br />
  If there is not enough space to display a graph you will be unable to enable it.
## Screenshots:
![2021-05-24_20 29 15](https://user-images.githubusercontent.com/18647702/119422445-19adba00-bccf-11eb-95db-68c728e72555.png)
![2021-05-24_20 29 36](https://user-images.githubusercontent.com/18647702/119422446-1a465080-bccf-11eb-85c4-6e60e31b2869.png)
![2021-05-24_20 30 04](https://user-images.githubusercontent.com/18647702/119422448-1a465080-bccf-11eb-8c5d-f479c263da62.png)
![2021-05-24_20 30 35](https://user-images.githubusercontent.com/18647702/119422461-25997c00-bccf-11eb-9be3-9b2ad6b355bf.png)
![2021-05-24_20 30 13](https://user-images.githubusercontent.com/18647702/119422464-27fbd600-bccf-11eb-8a38-61909bb6aae8.png)

## Known Issues
- If the reactor has a very large max RF/t generation capacity but a low RF/t drain, it may oscillate around the target buffer. This is partly due to my inexperience with setting PID constants, so any help here would be appreciated.
  - Workaround: increase the range of the buffer, YMMV
- Sometimes, the RF/t Drain statistic will fluctuate wildly. I don't think this is caused by the program, but in singleplayer, the issue seems to start when directly interacting with the reactor UI, and seems to get better by relogging.

## Future Plans
- Turbine support
- Fully customizable colors
  
## Update History
Last update: 12/14/2024 <p>
  <b>12/14/2024:</b> Fix issue with Pastebin API, and some major internal code refactors <p>
  <b>12/04/2023:</b> Changed Control rod insertion logic to use a PID controller <p>
  <b>5/24/2021:</b> Added support for Extreme Reactors and Big Reactors <p>
  <b>5/24/2021:</b> Started tracking update history / Uploaded to GitHub <p>

## Attributions
<ul>
  <li><b>Krakaen: </b><br />
    Gui design influenced by Krakaen's Reactor Program <br />
    http://www.computercraft.info/forums2/index.php?/topic/26019-big-reactors-automatic-control-program/ </li>
  <li><b>Lyqyd: </b><br />
    Buttons use Touchpoint API, though it was slightly modified <br />
    http://www.computercraft.info/forums2/index.php?/topic/14784-touchpoint-api/ </li>
 </ul>
