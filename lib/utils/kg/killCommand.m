function killCommand()
%KILLCOMMAND 

evalin('base','killer()');
end



function killer()
import java.awt.Robot
import java.awt.event.KeyEvent;

robit = Robot;
robit.keyPress(KeyEvent.VK_CONTROL);
robit.keyPress(KeyEvent.VK_C);
robit.keyRelease(KeyEvent.VK_CONTROL);
robit.keyRelease(KeyEvent.VK_C);


fprintf('Killing...\n');

end