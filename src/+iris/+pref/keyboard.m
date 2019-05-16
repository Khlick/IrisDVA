classdef keyboard < iris.infra.StoredPrefs
  
  properties
    b
    d
    f
    h
    i
    m
    n
    o
    p
    q
    r
    s
    t
    x
    rightarrow
    leftarrow
    uparrow
    downarrow
  end
  
  methods
    
    % B key
    function a = get.b(obj)
      sc = iris.pref.keyboard.createKeyCode(0,0,1,'toggleBaseline');
      a = obj.get('b',sc);
    end
    function set.b(obj,v)%#ok
      % for now we won't allow overrride
      v = iris.pref.keyboard.createKeyCode(0,0,1,'toggleBaseline');
      obj.put('b',v);
    end
    
    % D key
    function a = get.d(obj)
      sc = iris.pref.keyboard.createKeyCode(1,0,0,'menuAnalyze');
      a = obj.get('d',sc);
    end
    function set.d(obj,v)%#ok
      % for now we won't allow overrride
      v = iris.pref.keyboard.createKeyCode(1,0,0,'menuAnalyze'); 
      obj.put('d',v);
    end
    
    % F key
    function a = get.f(obj)
      sc = iris.pref.keyboard.createKeyCode(0,0,1,'toggleFilter');
      a = obj.get('f',sc);
    end
    function set.f(obj,v)%#ok
      % for now we won't allow overrride
      v = iris.pref.keyboard.createKeyCode(0,0,1,'toggleFilter'); 
      obj.put('f',v);
    end
    
    % H key
    function a = get.h(obj)
      sc = iris.pref.keyboard.createKeyCode(1,0,0,'menuHelp');
      a = obj.get('h',sc);
    end
    function set.h(obj,v)%#ok
      % for now we won't allow overrride
      v = iris.pref.keyboard.createKeyCode(1,0,0,'menuHelp'); 
      obj.put('h',v);
    end
    
    % I key
    function a = get.i(obj)
      sc = iris.pref.keyboard.createKeyCode(1,0,0,'menuFileInfo');
      a = obj.get('i',sc);
    end
    function set.i(obj,v)%#ok
      % for now we won't allow overrride
      v = iris.pref.keyboard.createKeyCode(1,0,0,'menuFileInfo'); 
      obj.put('i',v);
    end
    
    % M key
    function a = get.m(obj)
      sc = iris.pref.keyboard.createKeyCode(1,0,0,'actionCommand');
      a = obj.get('m',sc);
    end
    function set.m(obj,v)%#ok
      % for now we won't allow overrride
      v = iris.pref.keyboard.createKeyCode(1,0,0,'actionCommand'); 
      obj.put('m',v);
    end
    
    % N key
    function a = get.n(obj)
      sc = [ ...
        iris.pref.keyboard.createKeyCode(1,0,0,'actionNewData'); ...
        iris.pref.keyboard.createKeyCode(1,0,1,'actionImportData') ...
        ];
      a = obj.get('n',sc);
    end
    function set.n(obj,v)%#ok
      % for now we won't allow overrride
      v = [ ...
        iris.pref.keyboard.createKeyCode(1,0,0,'actionNewData'); ...
        iris.pref.keyboard.createKeyCode(1,0,1,'actionImportData') ...
        ];
      obj.put('n',v);
    end
    
    % O key
    function a = get.o(obj)
      sc = [ ...
        iris.pref.keyboard.createKeyCode(1,0,0,'actionNewSession'); ...
        iris.pref.keyboard.createKeyCode(1,0,1,'actionImportSession') ...
        ];
      a = obj.get('o',sc);
    end
    function set.o(obj,v)%#ok
      % for now we won't allow overrride
      v = [ ...
        iris.pref.keyboard.createKeyCode(1,0,0,'actionNewSession'); ...
        iris.pref.keyboard.createKeyCode(1,0,1,'actionImportSession') ...
        ];
      obj.put('o',v);
    end
    
    % P key
    function a = get.p(obj)
      sc = [ ...
        iris.pref.keyboard.createKeyCode(1,0,0,'menuProtocols'); ...
        iris.pref.keyboard.createKeyCode(1,0,1,'actionScreenshot') ...
        ];
      a = obj.get('p',sc);
    end
    function set.p(obj,v)%#ok
      % for now we won't allow overrride
      v = [ ...
        iris.pref.keyboard.createKeyCode(1,0,0,'menuProtocols'); ...
        iris.pref.keyboard.createKeyCode(1,0,1,'actionScreenshot') ...
        ];
      obj.put('p',v);
    end
    
    % Q key
    function a = get.q(obj)
      sc = iris.pref.keyboard.createKeyCode(1,0,0,'actionQuit');
      a = obj.get('q',sc);
    end
    function set.q(obj,v)%#ok
      % for now we won't allow overrride
      v = iris.pref.keyboard.createKeyCode(1,0,0,'actionQuit'); 
      obj.put('q',v);
    end
    
    % S key
    function a = get.s(obj)
      sc = [ ...
        iris.pref.keyboard.createKeyCode(1,0,0,'actionSave'); ...
        iris.pref.keyboard.createKeyCode(0,0,1,'toggleStatistics') ...
        ];
      a = obj.get('s',sc);
    end
    function set.s(obj,v)%#ok
      % for now we won't allow overrride
      v = [ ...
        iris.pref.keyboard.createKeyCode(1,0,0,'actionSave'); ...
        iris.pref.keyboard.createKeyCode(0,0,1,'toggleStatistics') ...
        ];
      obj.put('s',v);
    end
    
    % T key
    function a = get.t(obj)
      sc = iris.pref.keyboard.createKeyCode(1,0,0,'menuNotes');
      a = obj.get('t',sc);
    end
    function set.t(obj,v)%#ok
      % for now we won't allow overrride
      v = iris.pref.keyboard.createKeyCode(1,0,0,'menuNotes'); 
      obj.put('t',v);
    end
    
    % X key
    function a = get.x(obj)
      sc = iris.pref.keyboard.createKeyCode(0,0,0,'toggleEpoch');
      a = obj.get('x',sc);
    end
    function set.x(obj,v)%#ok
      % for now we won't allow overrride
      v = iris.pref.keyboard.createKeyCode(0,0,0,'toggleEpoch'); 
      obj.put('x',v);
    end
    
    % RIGHTARROW key
    function a = get.rightarrow(obj)
      sc = [ ...
        iris.pref.keyboard.createKeyCode(0,0,0,'navigateSmallRight'); ...
        iris.pref.keyboard.createKeyCode(0,1,0,'navigateBigRight'); ...
        iris.pref.keyboard.createKeyCode(0,0,1,'navigateWithinRight'); ...
        iris.pref.keyboard.createKeyCode(1,0,0,'navigateEndRight') ...
        ];
      a = obj.get('rightarrow',sc);
    end
    function set.rightarrow(obj,v)%#ok
      % for now we won't allow overrride
      v = [ ...
        iris.pref.keyboard.createKeyCode(0,0,0,'navigateSmallRight'); ...
        iris.pref.keyboard.createKeyCode(0,1,0,'navigateBigRight'); ...
        iris.pref.keyboard.createKeyCode(0,0,1,'navigateWithinRight'); ...
        iris.pref.keyboard.createKeyCode(1,0,0,'navigateEndRight') ...
        ];
      obj.put('rightarrow',v);
    end
    
    % LEFTARROW key
    function a = get.leftarrow(obj)
      sc = [ ...
        iris.pref.keyboard.createKeyCode(0,0,0,'navigateSmallLeft'); ...
        iris.pref.keyboard.createKeyCode(0,1,0,'navigateBigLeft'); ...
        iris.pref.keyboard.createKeyCode(0,0,1,'navigateWithinLeft'); ...
        iris.pref.keyboard.createKeyCode(1,0,0,'navigateEndLeft') ...
        ];
      a = obj.get('leftarrow',sc);
    end
    function set.leftarrow(obj,v)%#ok
      % for now we won't allow overrride
      v = [ ...
        iris.pref.keyboard.createKeyCode(0,0,0,'navigateSmallLeft'); ...
        iris.pref.keyboard.createKeyCode(0,1,0,'navigateBigLeft'); ...
        iris.pref.keyboard.createKeyCode(0,0,1,'navigateWithinLeft'); ...
        iris.pref.keyboard.createKeyCode(1,0,0,'navigateEndLeft') ...
        ];
      obj.put('leftarrow',v);
    end
    
    % UPARROW key
    function a = get.uparrow(obj)
      sc = [ ...
        iris.pref.keyboard.createKeyCode(0,0,0,'navigateSmallUp'); ...
        iris.pref.keyboard.createKeyCode(0,1,0,'navigateBigUp') ...
        ];
      a = obj.get('uparrow',sc);
    end
    function set.uparrow(obj,v)%#ok
      % for now we won't allow overrride
      v = [ ...
        iris.pref.keyboard.createKeyCode(0,0,0,'navigateSmallUp'); ...
        iris.pref.keyboard.createKeyCode(0,1,0,'navigateBigUp') ...
        ];
      obj.put('uparrow',v);
    end
    
    % DOWNARROW key
    function a = get.downarrow(obj)
      sc = [ ...
        iris.pref.keyboard.createKeyCode(0,0,0,'navigateSmallDown'); ...
        iris.pref.keyboard.createKeyCode(0,1,0,'navigateBigDown') ...
        ];
      a = obj.get('downarrow',sc);
    end
    function set.downarrow(obj,v)%#ok
      % for now we won't allow overrride
      v = [ ...
        iris.pref.keyboard.createKeyCode(0,0,0,'navigateSmallDown'); ...
        iris.pref.keyboard.createKeyCode(0,1,0,'navigateBigDown') ...
        ];
      obj.put('downarrow',v);
    end
    
    % ESCAPE key
    function a = get.r(obj)
      sc = iris.pref.keyboard.createKeyCode(0,0,0,'actionResetView');
      a = obj.get('r',sc);
    end
    function set.r(obj,v)%#ok
      % for now we won't allow overrride
      v = iris.pref.keyboard.createKeyCode(0,0,0,'actionResetView');
      obj.put('r',v);
    end
    
  end
  
  methods (Static)
    function d = getDefault()
      persistent default;
      if isempty(default) || ~isvalid(default)
        default = iris.pref.keyboard();
      end
      d = default;
    end
  end
  
  methods (Access = private, Static = true)
    function sc = createKeyCode(ctr,shf,alt,action)
      sc = struct( ...
        'CTRL', ctr, ...
        'SHIFT', shf, ...
        'ALT', alt, ...
        'ACTION', action ...
        );
    end
  end
  
end

