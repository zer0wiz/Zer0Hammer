@AutoHotKeys-manual.md 과 @autohotkeys @modules @AutoHotKeys.spoon 이 전부 다음 프로젝트에 리소스 들이였는데, 의도에서 자꾸 빗나가는거 같아 새로 만들 생각이야.
기존 파일을 설명을 하면 manual은 현재 기능 구현 목표등을 작성하기 위한것이고 플랜을 짜기 위한 용도
autohotkey/* 는 AutoHotKeys의 설정파일들의 저장 폴더
modules는 AutoHotKeys뿐 아니라 이후 Hammerspoon에서 공통/전역으로 사용하기 위한 모듈이고,
AutoHotKeys.spoon가 실제 구현하려는 프로젝트의 루트 폴더야.

newAutoHotKeys.spoon
- 목적: 기존 AutoHotKeys를 새롭게 구성하고 설계
- 묙포: 현재 포커스 된 app 또는 브라우저 각각 서로 다른 hotkey 기능을 추가
- contextInfo: 앱 또는 브라우저의 정보를 조회하는 모듈
- menu : 포커스된 app또는 브라우저의 hotkey 기능을 설정하기 위한 용도
- 주요 동작
 1. AutoHotKeys가 Hammerspoon에 로드될 때, menu 객체 생성 및 autohotkey에 설정을 조회하거나 저장할 수 있는 storage 로드
  1. 앱 또는 브라우저가 포커스 되었을 때 마다 contextInfo모듈을 통해 어플리케이션 정보를 조회한다.
  2. 1번을를 통해 조회된 context.id 기준으로 AutoHotKeys의 obj.context.list 항목에 존재 유무를 확인한다
  3. context.list에 존재할 경우 enabled 의 true/false 여부에 따라 AutoHotKey의 기능을 활성화 유무를 판단한다.
  4. 2에서 context.list에 없을 경우는 enabled=false와 동일하게 비활성상태로 간주한다.
  5. 단축키(`ctrl + cmd + k`)를 통해 menu를 표시할 수 있다.
  6. menu는 현재 마우스 포인트 위치를 기준으로 표시되며, 1번 에서 조회된 context 기준으로 context.list에 존재할 경우 menu에 설정 정보를 불러와서 표시하고, 존재하지 않을 경우에는 신규 메뉴 객체를 생성하여 
     
  b. contextI하고, 기존설정에 enabled 유무를 확인하여, on 일 경우에는 저장된 shortcuts를 기준으로 hotkey기능을 사용한다.


   a. 지정한 위치의 마우스 클릭 액션
   b. macro 기능로 저장된 기능을 실행