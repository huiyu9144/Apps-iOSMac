using System.Collections.Generic;

namespace JiaRemoteWin
{
    public static class WindowsKeyMapper
    {
        public static readonly Dictionary<System.Windows.Input.Key, (ushort MacKeyCode, bool NeedsShift)> KeyMap = new()
        {
            { System.Windows.Input.Key.A, (0, false) }, { System.Windows.Input.Key.B, (11, false) },
            { System.Windows.Input.Key.C, (8, false) }, { System.Windows.Input.Key.D, (2, false) },
            { System.Windows.Input.Key.E, (14, false) }, { System.Windows.Input.Key.F, (3, false) },
            { System.Windows.Input.Key.G, (5, false) }, { System.Windows.Input.Key.H, (4, false) },
            { System.Windows.Input.Key.I, (34, false) }, { System.Windows.Input.Key.J, (38, false) },
            { System.Windows.Input.Key.K, (40, false) }, { System.Windows.Input.Key.L, (37, false) },
            { System.Windows.Input.Key.M, (46, false) }, { System.Windows.Input.Key.N, (45, false) },
            { System.Windows.Input.Key.O, (31, false) }, { System.Windows.Input.Key.P, (35, false) },
            { System.Windows.Input.Key.Q, (12, false) }, { System.Windows.Input.Key.R, (15, false) },
            { System.Windows.Input.Key.S, (1, false) }, { System.Windows.Input.Key.T, (17, false) },
            { System.Windows.Input.Key.U, (32, false) }, { System.Windows.Input.Key.V, (9, false) },
            { System.Windows.Input.Key.W, (13, false) }, { System.Windows.Input.Key.X, (7, false) },
            { System.Windows.Input.Key.Y, (16, false) }, { System.Windows.Input.Key.Z, (6, false) },
            { System.Windows.Input.Key.D0, (29, false) }, { System.Windows.Input.Key.D1, (18, false) },
            { System.Windows.Input.Key.D2, (19, false) }, { System.Windows.Input.Key.D3, (20, false) },
            { System.Windows.Input.Key.D4, (21, false) }, { System.Windows.Input.Key.D5, (23, false) },
            { System.Windows.Input.Key.D6, (22, false) }, { System.Windows.Input.Key.D7, (26, false) },
            { System.Windows.Input.Key.D8, (28, false) }, { System.Windows.Input.Key.D9, (25, false) },
            { System.Windows.Input.Key.Space, (49, false) },
            { System.Windows.Input.Key.Return, (36, false) },
            { System.Windows.Input.Key.Tab, (48, false) },
            { System.Windows.Input.Key.Back, (51, false) },
            { System.Windows.Input.Key.Delete, (117, false) },
            { System.Windows.Input.Key.Escape, (53, false) },
            { System.Windows.Input.Key.Left, (123, false) },
            { System.Windows.Input.Key.Right, (124, false) },
            { System.Windows.Input.Key.Up, (126, false) },
            { System.Windows.Input.Key.Down, (125, false) },
            { System.Windows.Input.Key.Home, (115, false) },
            { System.Windows.Input.Key.End, (119, false) },
            { System.Windows.Input.Key.PageUp, (116, false) },
            { System.Windows.Input.Key.PageDown, (121, false) },
            { System.Windows.Input.Key.LeftCtrl, (59, false) },
            { System.Windows.Input.Key.RightCtrl, (62, false) },
            { System.Windows.Input.Key.LeftAlt, (58, false) },
            { System.Windows.Input.Key.RightAlt, (61, false) },
            { System.Windows.Input.Key.LeftShift, (56, false) },
            { System.Windows.Input.Key.RightShift, (60, false) },
            { System.Windows.Input.Key.LWin, (55, false) },
            { System.Windows.Input.Key.RWin, (55, false) },
            { System.Windows.Input.Key.OemMinus, (27, false) },
            { System.Windows.Input.Key.OemPlus, (24, false) },
            { System.Windows.Input.Key.OemOpenBrackets, (33, false) },
            { System.Windows.Input.Key.OemCloseBrackets, (30, false) },
            { System.Windows.Input.Key.OemBackslash, (42, false) },
            { System.Windows.Input.Key.OemSemicolon, (41, false) },
            { System.Windows.Input.Key.OemQuotes, (39, false) },
            { System.Windows.Input.Key.OemComma, (43, false) },
            { System.Windows.Input.Key.OemPeriod, (47, false) },
            { System.Windows.Input.Key.OemQuestion, (44, false) },
            { System.Windows.Input.Key.OemTilde, (50, false) },
            { System.Windows.Input.Key.F1, (122, false) }, { System.Windows.Input.Key.F2, (120, false) },
            { System.Windows.Input.Key.F3, (99, false) }, { System.Windows.Input.Key.F4, (118, false) },
            { System.Windows.Input.Key.F5, (96, false) }, { System.Windows.Input.Key.F6, (97, false) },
            { System.Windows.Input.Key.F7, (98, false) }, { System.Windows.Input.Key.F8, (100, false) },
            { System.Windows.Input.Key.F9, (101, false) }, { System.Windows.Input.Key.F10, (109, false) },
            { System.Windows.Input.Key.F11, (103, false) }, { System.Windows.Input.Key.F12, (111, false) },
            { System.Windows.Input.Key.CapsLock, (57, false) },
        };

        public static (ushort keyCode, ulong flags) MapKey(System.Windows.Input.Key key, bool isDown)
        {
            if (KeyMap.TryGetValue(key, out var mapping))
            {
                ulong flags = 0;
                if (!isDown) flags |= 0x100;
                return (mapping.MacKeyCode, flags);
            }
            return (0xFFFF, 0);
        }
    }
}
