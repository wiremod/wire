FPGAHelperHTML = [[
<!DOCTYPE html>
<html>
  <head>
    <style>
      body {background-color: white; margin-right: 30px;}
      h2 {margin-bottom: 0;}
      h4 {margin-bottom: 0;}
    </style>
  </head>
  <body>
    <h1>FPGA Help</h1>

    <h2>Types</h2>
    <div class="col" style="margin-left: 20px;">
      <table>
        <tr>
          <th style="width: 60px;">Type</th>
          <th style="width: 80px;">Color</th>
        </tr>
        <tr>
          <td>Normal</td>
          <td style="background-color: rgb(190, 190, 255)"></td>
        </tr>
        <tr>
          <td>Vector</td>
          <td style="background-color: rgb(70, 160, 255)"></td>
        </tr>
        <tr>
          <td>Angle</td>
          <td style="background-color: rgb(100, 200, 100)"></td>
        </tr>
        <tr>
          <td>String</td>
          <td style="background-color: rgb(250, 160, 90)"></td>
        </tr>
        <tr>
          <td>Array</td>
          <td style="background-color: rgb(20, 110, 20)"></td>
        </tr>
        <tr>
          <td>Entity</td>
          <td style="background-color: rgb(255, 100, 100)"></td>
        </tr>
        <tr>
          <td>Ranger</td>
          <td style="background-color: rgb(130, 100, 60)"></td>
        </tr>
        <tr>
          <td>Wirelink</td>
          <td style="background-color: rgb(200, 80, 200)"></td>
        </tr>
      </table>
    </div>

    <h2>Controls</h2>
    <div class="col" style="margin-left: 20px;">
      <table>
        <tr>
          <th style="width: 130px;">Key</th>
          <th>Effect</th>
        </tr>
        <tr>
          <td>Left mouse button</td>
          <td>Used to move gates, draw connections, and draw selections</td>
        </tr>
        <tr>
          <td>Right mouse button</td>
          <td>Hold and drag mouse around to move around the internals of the FPGA</td>
        </tr>
        <tr>
          <td>C</td>
          <td>Creates a gate at the cursor position. Select which gate in the gate selector on the right</td>
        </tr>
        <tr>
          <td>X</td>
          <td>Removes the gate under the cursor. If a selection has been made, it will delete all selected gates</td>
        </tr>
        <tr>
          <td>E</td>
          <td>Edits a property of the gate under the cursor. Applicable for Input, Output and Constant gates</td>
        </tr>
        <tr>
          <td>Ctrl C</td>
          <td>Copies the selected nodes</td>
        </tr>
        <tr>
          <td>Ctrl V</td>
          <td>Pastes the previously copied nodes, and marks the pasted nodes as selected</td>
        </tr>
      </table>
    </div>

    <h2>Execution</h2>
    <div class="col" style="margin-left: 20px;">
      <p>The FPGA can be made to execute on different conditions.
        As default, it will execute if one of the inputs changes, or if it has a <i>timed</i> gate (as marked by red) inside it.
        It should be noted that if 2 different inputs change the same tick, the FPGA will execute twice, 
        where the first execution will be with an old value for one of the inputs. This is due to how Wiremod works, where only one input is triggered at a time.
      </p>
      <p>
        To further customize chip execution, there are 3 different ways a chip can trigger an execution.
      </p>
      <h4>On input changed</h4>
      <div class="col" style="margin-left: 20px;">
        <p>
          The chip executes when an input is changed, and propogates the changes inside it, updating the gates affected by the input change.
          Gates that aren't affected by the input change, will not execute.
        </p>
      </div>
      <h4>Timed</h4>
      <div class="col" style="margin-left: 20px;">
        <p>
          Timed execution only affects gates which are timed (marked by red). 
          This includes gates such as 'OS Time', 'Entity Position', which share the property that their output is time dependant.
          For these gates to always have the correct output, timed execution needs to be on.
          The frequency that these timed gates are updated with can be controlled with the <b>Execution Interval</b> setting.
        </p>
      </div>
      <h4>On trigger</h4>
      <div class="col" style="margin-left: 20px;">
        <p>
          For the greatest control over executions, the other options can be turned off and this one turned on.
          The gate will get a "Trigger" input, which when set to something other than 0, will cause the chip to execute everything necessary.
          The FPGA keeps a "lazy queue", such that it knows which gates will need to execute when the "Trigger" input is triggered.
          This includes all timed gates, and input gates which have had their value changed since last trigger.
        </p>
      </div>
      <br>
      <h3>Special execution gates</h3>
      <div class="col" style="margin-left: 20px;">
        <p>
          To further customize how a chip executes, some special execution gates have been included.
          They can be found under FPGA/Execution
          <h4>Execution Delta</h4>
          <div class="col" style="margin-left: 20px;">
            <p>
              This chip will return the time between the current execution and the last one.
              Useful for time critical circuitry - such as levitating - or calculations where the time difference is required.
            </p>
          </div>
          <h4>Last (Normal/Vector/Angle/String)</h4>
          <div class="col" style="margin-left: 20px;">
            <p>
              Mainly designed to allow looping circuitry. For example, a memory gate feeding it's own value + 1 into itself will produce an infinite loop.
              If a Last gate is put somewhere in the loop, it will allow it to be executed. It does this by using the last value of the gate connected to it's input,
              'disengaging' the infinite loop.
            </p>
          </div>
          <h4>Previous (Normal/Vector/Angle/String)</h4>
          <div class="col" style="margin-left: 20px;">
            <p>
              An alternative to the Last gate, that functions a bit differently. This gate will output the value the connected gate had the previous tick,
              which differs from the Last gate behaviour both because multiple executions can happen each tick, which will cause the Last gate to change, but not the Previous gate.
              The most important difference, is that the Previous gate will trigger a new execution during next tick, with the updated value.
              This can cause a chain reaction, if this execution changes the Previous gate, causing it to trigger next tick again.
            </p>
          </div>
        </p>
      </div>
    </div>

  </body>
</html>
]]